# 006 - Jenkins CI: Enterprise Pipeline Engineering & Distributed Automation

In Module 003, I implemented modern, cloud-native continuous integration workflows using GitHub Actions. In enterprise engineering organizations—particularly across finance, defense, telecom, and healthcare—automation pipelines often run on **Jenkins**, the open-source automation server that established the CI/CD industry.

While modern cloud platforms abstract away compute infrastructure, enterprise DevOps engineers frequently maintain, scale, or migrate legacy Jenkins installations. Managing Jenkins requires understanding self-hosted architecture, distributed master/agent execution, plugin governance, and pipeline authoring in Groovy.

In this module, I deploy an optimized, lightweight Jenkins Controller environment, author a production-grade **Declarative `Jenkinsfile`**, execute multi-stage builds, and document a side-by-side architectural translation between Jenkins and GitHub Actions.

---

## 1. Jenkins Architecture & Core Primitives

Understanding Jenkins requires understanding its distributed execution model:

```text
+--------------------------------------------------------------+
|                    Jenkins Controller (Master)                |
|  - Web UI & REST API (:8080)                                 |
|  - Pipeline Orchestration & Groovy Parser                     |
|  - Plugin Engine & Credentials Store                         |
|  - Job Scheduling & Dispatcher (:50000 JNLP)                 |
+------------------------------+-------------------------------+
                               |
            +------------------+------------------+
            | Dispatch Work                       | Dispatch Work
            v                                     v
+-----------------------+             +-----------------------+
|   Agent Node 1 (Linux)|             |   Agent Node 2 (Docker|
|  - Executes build     |             |     / Kubernetes Pod) |
|  - Streams logs back  |             |  - Ephemeral build    |
|  - Workspace storage  |             |  - Destroyed on finish|
+-----------------------+             +-----------------------+
```

### The Controller (Master)
The Controller is the brains of the system. It hosts the administrative Web UI on port `8080`, manages the internal H2/disk configuration, stores credentials securely, parses pipeline definitions, and coordinates work. Best practice dictates that the Controller should **never run heavy build workloads directly**; builds must be delegated to Agents to keep the Controller responsive and stable.

### The Agents (Nodes / Workers)
Agents are worker instances that execute the actual shell scripts, compiler passes, and container builds. They communicate with the Controller via:
- **JNLP (Java Network Launch Protocol) / Inbound Agent:** The agent connects inbound to the Controller on TCP port `50000`. Ideal for agents running inside firewalled environments, private clouds, or dynamic Kubernetes pods.
- **SSH:** The Controller connects outbound to the agent over SSH using private key credentials.

### Declarative vs. Scripted Pipelines (Groovy)
Jenkins pipelines are written in **Apache Groovy**. Jenkins supports two approaches:
1. **Declarative Pipeline (Modern Standard):** Begins with `pipeline { ... }`. Highly structured, strict, opinionated syntax with predefined blocks (`agent`, `stages`, `steps`, `post`). Jenkins parses and validates the syntax before starting any job execution, preventing mid-run syntax failures.
2. **Scripted Pipeline (Legacy):** Begins with `node { ... }`. Freeform Groovy programming allowing arbitrary loops, variables, and procedural logic. While powerful, it often produces complex, unmaintainable pipeline code.

---

## 2. Directory Layout

```text
006-jenkins-ci/
├── README.md               # Architectural notes, hands-on lab, and translation guide
├── docker-compose.yaml     # Lightweight Jenkins Controller container configuration
└── Jenkinsfile             # Production-grade Declarative pipeline (Groovy)
```

---

## 3. Step-by-Step Hands-On Implementation

### Step 1: Deploy the Jenkins Controller via Docker Compose
To test Jenkins locally without overloading system resources, I deploy an optimized Controller using Docker Compose. The environment caps the JVM heap size (`-Xmx512m -Xms256m`), exposes port `8080` (HTTP) and port `50000` (JNLP), and runs the official native ARM64 image (`jenkins/jenkins:lts-jdk21`) attached to a dedicated bridge network (`jenkins-net`):

```bash
cd 006-jenkins-ci
docker compose up -d
```

I verify that the controller container is healthy and running:
```bash
docker compose ps
```

---

### Step 2: Retrieve the Initial Admin Password & Access the UI
When Jenkins boots for the first time, it generates a secure cryptographic token to authenticate the initial administrator.

I retrieve the initial password from the container logs:
```bash
docker compose logs jenkins-controller | grep -A 2 "Please use the following password"
```
*(Alternatively, I can read the file directly inside the container volume:)*
```bash
docker exec jenkins-controller cat /var/jenkins_home/secrets/initialAdminPassword
```

1. I navigate to `http://localhost:8080` in the browser.
2. I paste the admin password into the prompt and click **Continue**.
3. I select **Install suggested plugins** (installing core plugins: Git, Pipeline, Workspace Cleanup, Folders).
4. I create the primary administrator credentials and confirm the instance root URL (`http://localhost:8080`).

---

### Step 3: Hardening the Controller (Built-In Node Executors to 0)
In an enterprise architecture, the controller must never execute arbitrary build jobs, compile source code, or run test suites. Running workloads on the controller risks JVM out-of-memory crashes, disk exhaustion, and unauthorized administrative access.

To enforce distributed execution:
1. I navigate to **Manage Jenkins -> Nodes**.
2. I select **Built-In Node**, click **Configure**.
3. I change the **Number of executors** from `2` to `0`.
4. I click **Save**.

Now, any scheduled job is forced to wait for an external worker node with matching labels.

---

### Step 4: Register and Launch a Containerized Inbound Agent
To execute jobs, I deploy an isolated worker container running the official Jenkins inbound agent image (`jenkins/inbound-agent:latest`).

#### 1. Register the Agent Node in the UI
1. In **Manage Jenkins -> Nodes**, I click **New Node**.
2. Node name: `docker-agent`.
3. Type: **Permanent Agent**, then click **Create**.
4. I configure the agent properties:
   - **Number of executors**: `2`
   - **Remote root directory**: `/home/jenkins/agent`
   - **Labels**: `docker-agent`
   - **Usage**: `Use this node as much as possible`
   - **Launch method**: `Launch agent by connecting it to the controller` (WebSocket / Inbound remoting)
5. I click **Save**.
6. I click on the newly created `docker-agent` in the list to view its connection command and secret token.

#### 2. Launch the Agent Container
I launch the agent container attached to the same Docker network as the controller (`006-jenkins-ci_jenkins-net`), passing the secret token, controller URL, and agent name:

```bash
docker run -d \
  --name jenkins-agent \
  --network 006-jenkins-ci_jenkins-net \
  jenkins/inbound-agent:latest \
  -url http://jenkins-controller:8080/ \
  -secret <AGENT_SECRET> \
  -name docker-agent \
  -workDir /home/jenkins/agent
```

I inspect the agent logs to confirm successful connection:
```bash
docker logs jenkins-agent
```
The output confirms:
```text
INFO: Remote identity confirmed
INFO: Connected
```
In the Jenkins UI, the status icon for `docker-agent` switches from offline to online with 2 idle executors available.

---

### Step 5: Connect Pipeline to GitHub SCM (Pipeline as Code)
In enterprise engineering, pasting pipeline scripts directly into the UI is an anti-pattern because the code is not version-controlled, auditable, or subject to peer review. Instead, I adopt the industry standard: **Pipeline script from SCM**, where Jenkins dynamically pulls the `Jenkinsfile` directly from GitHub on every execution.

#### 1. Push Branch to GitHub
Before Jenkins can clone the repository, I commit and push my local branch to GitHub.

#### 2. Configure the Pipeline Job in Jenkins
1. On the Jenkins home screen, I click **New Item**.
2. I enter the name: `devops-pipeline-demo`.
3. I select **Pipeline** and click **OK**.
4. In the job configuration page, I scroll down to the **Pipeline** section.
5. In the **Definition** dropdown, I change from `Pipeline script` to **Pipeline script from SCM**.
6. Under **SCM**, I select **Git**.
7. In **Repository URL**, I enter:
   ```text
   https://github.com/adrianofarina/devops-portfolio.git
   ```
8. **Credentials**: I leave this set to `- none -` because the repository is public.
9. In **Branch Specifier (blank for 'any')**, I specify:
   ```text
   */feature/jenkins-ci
   ```
10. In **Script Path**, I enter the path to the pipeline manifest within the repository:
    ```text
    006-jenkins-ci/Jenkinsfile
    ```
11. I click **Save**.

---

### Step 6: Execute the Build, Inspect Stage View, and Verify Agent Execution
1. In the `devops-pipeline-demo` project dashboard, I click **Build Now**.
2. Under **Build History**, I click on build **#1**.
3. I inspect the **Stage View** visualization on the main project page, verifying that all stages execute sequentially:
   - **Initialize & Environment Audit:** Prints environment variables and system architecture.
   - **Code Quality & Linting:** Simulates syntax checking.
   - **Build & Package:** Generates a structured build artifact (`build/output/artifact.txt`).
   - **Automated Test Suite:** Evaluates smoke tests against the generated artifact.
   - **Deploy to Target Environment:** Conditional stage evaluating the `when { expression { ... } }` rule.
4. I click **Console Output** to inspect the raw execution log. I verify:
   - Jenkins successfully clones the repository from GitHub:
     ```text
     Checking out Revision ... (refs/remotes/origin/feature/jenkins-ci)
     ```
   - The workload executed strictly on the agent container:
     ```text
     Running on docker-agent in /home/jenkins/agent/workspace/devops-pipeline-demo
     ```
   - The `post { always { cleanWs ... } }` step cleaned up the temporary workspace inside the agent container.
   - The build concludes with:
     ```text
     Finished: SUCCESS
     ```

---

### Step 7: Teardown & Clean Up
Once the pipeline execution and verification are complete, I stop and remove all resources to completely free memory and disk space:

```bash
# Stop and remove the agent container
docker stop jenkins-agent && docker rm jenkins-agent

# Stop and remove the controller and its persistent volume
cd 006-jenkins-ci
docker compose down -v
```

I verify that no residual containers remain:
```bash
docker ps
```

---

## 4. Side-by-Side Architectural Translation: Jenkins vs. GitHub Actions

| Architectural Dimension | Jenkins (`Jenkinsfile`) | GitHub Actions (`workflow.yaml`) | Engineering Analysis |
| :--- | :--- | :--- | :--- |
| **Pipeline Definition** | Single `Jenkinsfile` written in **Groovy** | Multiple YAML workflows in `.github/workflows/*.yaml` | Groovy provides programmatic scriptability; YAML provides declarative simplicity and strict schemas. |
| **Execution Controller** | Self-hosted Jenkins Master / Controller | Managed GitHub cloud control plane | Jenkins requires server patching, disk management, and JVM tuning; GitHub Actions is fully managed SaaS. |
| **Worker / Runner Compute** | Static Nodes (VMs/servers) or dynamic Kubernetes Agent pods | Ephemeral hosted runners (`ubuntu-latest`) or self-hosted runner fleets | GitHub Actions provisions pristine, ephemeral VMs per job; Jenkins often reuses static workspaces unless container agents are used. |
| **Dependency Model** | Sequential linear stages (`stages { stage { ... } }`) | Directed Acyclic Graph (`needs: [jobA, jobB]`) | GitHub Actions executes jobs concurrently by default; Jenkins requires explicit `parallel { ... }` blocks. |
| **Ecosystem & Reusability** | Community Plugins (1,800+ Java plugins installed globally on Controller) | Reusable Actions (`uses: action@v4`) downloaded at job runtime | Jenkins plugins run in the Controller JVM process (plugin bugs can crash the server); GitHub Actions run isolated inside the runner VM. |
| **Credentials & Secrets** | Jenkins Credentials Store (`withCredentials([usernamePassword(...)])`) | Encrypted Secrets (`${{ secrets.MY_TOKEN }}`) & Environments | Jenkins encrypts secrets in `$JENKINS_HOME`; GitHub secures secrets using hardware security modules with repository-level and environment-level access controls. |
| **Conditional Logic** | `when { branch 'main' }` or `when { expression { ... } }` | `if: github.ref == 'refs/heads/main'` | Both allow branch-level, tag-level, and custom boolean conditional gating. |
| **Post-Execution Hooks** | `post { always { ... } success { ... } failure { ... } }` | `if: always()`, `if: success()`, `if: failure()` | Both support deterministic cleanup, notification dispatch, and failure handling. |

---

## 5. Enterprise Migration Strategy: Moving from Jenkins to GitHub Actions

DevOps engineers frequently lead migrations from legacy Jenkins servers to GitHub Actions to eliminate infrastructure overhead. When migrating enterprise pipelines:

1. **Deconstruct Global Plugins into Native Actions:** Legacy Jenkins pipelines rely heavily on plugins (NodeJS Plugin, Docker Pipeline Plugin, SonarQube Scanner). In GitHub Actions, these map directly to official actions (such as `actions/setup-node@v4` or `docker/build-push-action@v5`). I can discover verified actions on the [GitHub Marketplace](https://github.com/marketplace?type=actions), or browse them in real time via the built-in Marketplace sidebar inside GitHub's web workflow editor, which provides searchable snippets directly while typing.
2. **Transition Static Workspaces to Ephemeral Runners:** In static Jenkins agents, previous builds can leave dirty disk state (`node_modules`, cached binaries). GitHub Actions runners provide guaranteed clean environments out of the box.
3. **Map Secret Bindings:** Replace `withCredentials` Groovy blocks with GitHub Actions `${{ secrets.* }}` or OpenID Connect (OIDC) cloud federation to eliminate long-lived cloud credentials altogether.
4. **Shift from Sequential Stages to Parallel DAGs:** Legacy Jenkins jobs often run tests sequentially. Rewriting these stages as independent GitHub Actions jobs linked via `needs:` significantly cuts total delivery wall-clock time.
