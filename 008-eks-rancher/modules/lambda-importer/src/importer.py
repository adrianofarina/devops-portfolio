import base64
import json
import os
import ssl
import tempfile
import urllib.error
import urllib.request

import boto3
from botocore.signers import RequestSigner
import yaml

# Map Kubernetes kinds to their API plural paths and whether they belong to a namespace
K8S_RESOURCE_MAP = {
    "Namespace": ("namespaces", False),
    "ClusterRole": ("clusterroles", False),
    "ClusterRoleBinding": ("clusterrolebindings", False),
    "ServiceAccount": ("serviceaccounts", True),
    "Secret": ("secrets", True),
    "ConfigMap": ("configmaps", True),
    "Service": ("services", True),
    "Deployment": ("deployments", True),
    "Role": ("roles", True),
    "RoleBinding": ("rolebindings", True),
}


def get_ssm_param(ssm_client, name):
    resp = ssm_client.get_parameter(Name=name, WithDecryption=True)
    return resp["Parameter"]["Value"]


def http_request(url, method="GET", headers=None, data=None, ssl_ctx=None):
    req = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
    with urllib.request.urlopen(req, context=ssl_ctx, timeout=20) as resp:
        return resp.status, resp.read().decode("utf-8")


def rancher_login(rancher_url, password, ssl_ctx):
    login_url = f"{rancher_url}/v3-public/localProviders/local?action=login"
    payload = json.dumps({"username": "admin", "password": password}).encode("utf-8")
    _, body = http_request(
        login_url,
        method="POST",
        headers={"Content-Type": "application/json"},
        data=payload,
        ssl_ctx=ssl_ctx,
    )
    return json.loads(body)["token"]


def ensure_rancher_settings(rancher_url, token, ssl_ctx):
    """Make sure Rancher server-url matches the live ALB endpoint."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    try:
        http_request(
            f"{rancher_url}/v3/settings/server-url",
            method="PUT",
            headers=headers,
            data=json.dumps({"value": rancher_url}).encode("utf-8"),
            ssl_ctx=ssl_ctx,
        )
    except urllib.error.HTTPError as err:
        print(f"Warning updating server-url setting: {err.code}")


def get_or_create_cluster(rancher_url, token, cluster_name, ssl_ctx):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    _, body = http_request(
        f"{rancher_url}/v3/clusters?name={cluster_name}",
        headers=headers,
        ssl_ctx=ssl_ctx,
    )
    existing = json.loads(body).get("data", [])
    if existing:
        return existing[0]["id"]

    payload = json.dumps({"type": "cluster", "name": cluster_name}).encode("utf-8")
    _, created = http_request(
        f"{rancher_url}/v3/clusters",
        method="POST",
        headers=headers,
        data=payload,
        ssl_ctx=ssl_ctx,
    )
    return json.loads(created)["id"]


def get_import_manifest(rancher_url, token, cluster_id, ssl_ctx):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    payload = json.dumps(
        {"type": "clusterRegistrationToken", "clusterId": cluster_id}
    ).encode("utf-8")
    _, resp_body = http_request(
        f"{rancher_url}/v3/clusterregistrationtokens",
        method="POST",
        headers=headers,
        data=payload,
        ssl_ctx=ssl_ctx,
    )
    manifest_url = json.loads(resp_body)["manifestUrl"]
    _, manifest_yaml = http_request(manifest_url, headers=headers, ssl_ctx=ssl_ctx)
    return manifest_yaml


def get_eks_token(cluster_name, region):
    """Generate a short-lived EKS bearer token using boto3 STS pre-signing."""
    session = boto3.session.Session()
    client = session.client("sts", region_name=region)
    service_id = client.meta.service_model.service_id

    signer = RequestSigner(
        service_id,
        region,
        "sts",
        "v4",
        session.get_credentials(),
        session.events,
    )
    params = {
        "method": "GET",
        "url": f"https://sts.{region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
        "body": {},
        "headers": {"x-k8s-aws-id": cluster_name},
        "context": {},
    }
    signed_url = signer.generate_presigned_url(
        params, region_name=region, expires_in=60, operation_name=""
    )
    encoded = base64.urlsafe_b64encode(signed_url.encode("utf-8")).decode("utf-8").rstrip("=")
    return f"k8s-aws-v1.{encoded}"


def apply_k8s_manifest(manifest_yaml, cluster_endpoint, ca_b64, eks_token):
    ca_bytes = base64.b64decode(ca_b64)
    applied = []

    with tempfile.NamedTemporaryFile(delete=False) as ca_file:
        ca_file.write(ca_bytes)
        ca_path = ca_file.name

    try:
        k8s_ssl = ssl.create_default_context(cafile=ca_path)

        for doc in yaml.safe_load_all(manifest_yaml):
            if not doc or "kind" not in doc:
                continue

            kind = doc["kind"]
            api_version = doc["apiVersion"]
            metadata = doc.get("metadata", {})
            name = metadata["name"]
            namespace = metadata.get("namespace", "default")

            if kind not in K8S_RESOURCE_MAP:
                print(f"Skipping unsupported kind: {kind}")
                continue

            plural, is_namespaced = K8S_RESOURCE_MAP[kind]
            base = "/api/v1" if api_version == "v1" else f"/apis/{api_version}"
            collection_path = (
                f"{base}/namespaces/{namespace}/{plural}"
                if is_namespaced
                else f"{base}/{plural}"
            )

            create_url = f"{cluster_endpoint}{collection_path}"
            body = json.dumps(doc).encode("utf-8")
            headers = {
                "Authorization": f"Bearer {eks_token}",
                "Content-Type": "application/json",
            }

            try:
                http_request(create_url, method="POST", headers=headers, data=body, ssl_ctx=k8s_ssl)
                applied.append(f"created {kind}/{name}")
            except urllib.error.HTTPError as err:
                if err.code == 409:
                    patch_url = f"{create_url}/{name}"
                    patch_headers = {
                        "Authorization": f"Bearer {eks_token}",
                        "Content-Type": "application/merge-patch+json",
                    }
                    http_request(
                        patch_url,
                        method="PATCH",
                        headers=patch_headers,
                        data=body,
                        ssl_ctx=k8s_ssl,
                    )
                    applied.append(f"patched {kind}/{name}")
                else:
                    raise
    finally:
        if os.path.exists(ca_path):
            os.remove(ca_path)

    return applied


def lambda_handler(event, context):
    region = os.environ.get("AWS_REGION", "us-east-1")
    cluster_name = os.environ["WORKLOAD_CLUSTER_NAME"]
    rancher_url_param = os.environ["RANCHER_URL_PARAM"]
    rancher_pass_param = os.environ["RANCHER_PASS_PARAM"]

    ssm = boto3.client("ssm", region_name=region)
    rancher_url = get_ssm_param(ssm, rancher_url_param).rstrip("/")
    rancher_password = get_ssm_param(ssm, rancher_pass_param)

    # Rancher uses a self-signed TLS cert on the ALB in this lab
    rancher_ssl = ssl._create_unverified_context()

    token = rancher_login(rancher_url, rancher_password, rancher_ssl)
    ensure_rancher_settings(rancher_url, token, rancher_ssl)

    cluster_id = get_or_create_cluster(rancher_url, token, cluster_name, rancher_ssl)
    manifest_yaml = get_import_manifest(rancher_url, token, cluster_id, rancher_ssl)

    eks = boto3.client("eks", region_name=region)
    cluster_info = eks.describe_cluster(name=cluster_name)["cluster"]
    eks_token = get_eks_token(cluster_name, region)

    applied = apply_k8s_manifest(
        manifest_yaml,
        cluster_info["endpoint"],
        cluster_info["certificateAuthority"]["data"],
        eks_token,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Workload cluster imported into Rancher successfully",
                "rancher_cluster_id": cluster_id,
                "target_cluster": cluster_name,
                "resources_applied": applied,
            }
        ),
    }
