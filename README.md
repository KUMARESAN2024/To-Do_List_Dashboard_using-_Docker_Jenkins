# Deploy Kanban Dashboard Using Docker, Jenkins & AWS EC2

A CI/CD project that automates the build, containerization, publishing, deployment, and validation of a Kanban Dashboard application using **GitHub, Jenkins, Docker, Docker Hub, and AWS EC2**.

## Project Overview

This project implements an automated pipeline that takes application code from GitHub and deploys it to an AWS EC2 instance as a Docker container.

The intended workflow is:

```text
GitHub
   |
   v
Jenkins (GitHub webhook)
   |
   v
Checkout Source
   |
   v
Build Docker Image
   |
   v
Tag Image (build number / Git commit SHA)
   |
   v
Push Image to Docker Hub
   |
   v
Deploy Container on AWS EC2
   |
   v
Health Check & Validation
   |
   v
Deployment Success / Failure
```

Once the pipeline is configured, a GitHub push triggers the Jenkins pipeline automatically. Deployment success is determined by application health checks, not merely by whether the container starts.

## Objectives

- Run the Kanban Dashboard application locally before containerization.
- Create a multi-stage Docker image with a minimal runtime image.
- Apply Docker security practices, including a non-root runtime user and a `.dockerignore` file.
- Publish versioned Docker images to a container registry.
- Host Jenkins and the application container on AWS EC2.
- Automate build and deployment stages using a Jenkins Pipeline (`Jenkinsfile`).
- Trigger builds through a GitHub webhook.
- Validate deployments using Docker health status and an application endpoint.
- Capture logs and build output for successful and failed deployments.
- Limit container CPU and memory usage.

## Technology Stack

| Technology | Purpose |
|---|---|
| Git & GitHub | Source-code management and webhook trigger |
| Jenkins | CI/CD pipeline automation |
| Docker | Application containerization |
| Docker Hub | Docker image registry |
| AWS EC2 | Host for Jenkins and the deployed application |
| Ubuntu / Linux | EC2 operating system |
| Node.js / npm | Application runtime and dependency management, if used by the source project |

## Source Repository

Application repository:  
https://github.com/Vennilavanguvi/kanban-dashboard.git

## Project Structure

The exact repository layout may vary. The deployment-related files are expected to include:

```text
kanban-dashboard/
├── Dockerfile
├── .dockerignore
├── Jenkinsfile
├── package.json
├── package-lock.json
└── ... application source files
```

- `Dockerfile` — defines the multi-stage image build and runtime configuration.
- `.dockerignore` — excludes unnecessary files such as `node_modules`, `.git`, and environment files from the build context.
- `Jenkinsfile` — defines the automated CI/CD stages.
- `package.json` — contains application scripts and dependencies.

## Prerequisites

Before running the project, prepare:

- A GitHub account with access to the source repository.
- An AWS account and an Ubuntu EC2 instance.
- Docker installed on the EC2 instance.
- Jenkins installed and accessible on the EC2 instance.
- A Docker Hub account and repository.
- Required Jenkins plugins, such as:
  - Git
  - Docker Pipeline
  - Credentials Binding
- Jenkins credentials for registry access and any deployment access required by the pipeline.
- Git, Docker, and the application dependencies for local testing.

> Keep passwords, access tokens, private keys, and environment secrets in Jenkins Credentials or an appropriate secret store. Do not commit them to GitHub or place them in the Docker image.

## Application Setup

Clone the repository:

```bash
git clone https://github.com/Vennilavanguvi/kanban-dashboard.git
cd kanban-dashboard
```

Install dependencies and start the application using the scripts defined in `package.json`. For a typical npm project:

```bash
npm install
npm run
```

Use the appropriate start or development script shown by the project. Confirm the application works in a browser before building the Docker image.

Record the application's actual listening port and any required environment variables in your deployment notes. These values depend on the application configuration.

## Docker Containerization

The application is packaged using a multi-stage Docker build:

1. The build stage installs dependencies and creates the production build.
2. The runtime stage contains only the files required to serve the built application.
3. The image uses a minimal base image where practical.
4. The runtime process uses a non-root user.
5. A Docker `HEALTHCHECK` is included.
6. Only the required application port is exposed.

Build the image (replace the image name if needed):

```bash
docker build -t kanban-dashboard:local .
```

Run it locally, replacing `<APP_PORT>` with the port configured for the application:

```bash
docker run -d \
  --name kanban-dashboard \
  -p <APP_PORT>:<APP_PORT> \
  kanban-dashboard:local
```

Check the container:

```bash
docker ps
docker logs kanban-dashboard
docker inspect kanban-dashboard
```

Check its health status:

```bash
docker inspect --format='{{.State.Health.Status}}' kanban-dashboard
```

The health status is available when a Docker `HEALTHCHECK` is configured.

## Docker Security

The image and container configuration follow these practices:

- Use a minimal base image, such as an appropriate Alpine or slim image.
- Run the application as a dedicated non-root user.
- Exclude unnecessary files using `.dockerignore`.
- Do not include `.env` files, credentials, tokens, or private keys in the image.
- Avoid installing unnecessary packages.
- Expose only the application port required at runtime.

Inspect the configured runtime user:

```bash
docker inspect --format='{{.Config.User}}' kanban-dashboard
```

## Container Registry & Image Versioning

The built image is tagged with a unique build number or Git commit SHA rather than relying only on the mutable `latest` tag.

Example:

```bash
docker tag kanban-dashboard:local <DOCKERHUB_USERNAME>/kanban-dashboard:<VERSION>
docker login
docker push <DOCKERHUB_USERNAME>/kanban-dashboard:<VERSION>
```

Replace `<DOCKERHUB_USERNAME>` and `<VERSION>` with the actual Docker Hub username and build/version tag.

On the EC2 instance, verify that the published image can be pulled:

```bash
docker pull <DOCKERHUB_USERNAME>/kanban-dashboard:<VERSION>
```

## AWS EC2 Infrastructure

An Ubuntu EC2 instance is used to host Jenkins and the deployed application container.

Typical setup tasks:

1. Launch the EC2 instance.
2. Install and configure Docker.
3. Install and configure Jenkins.
4. Confirm that the Jenkins web interface is reachable.
5. Configure the EC2 security group to allow only the ports required by the deployment.

Common ports in this project:

| Port | Purpose |
|---|---|
| 22 | SSH administration |
| 8080 | Jenkins web interface |
| `<APP_PORT>` | Kanban Dashboard application |

Restrict inbound access to trusted IP addresses wherever possible. Do not expose administrative services publicly without appropriate access controls.

## Jenkins Configuration

Configure Jenkins with the required plugins and credentials.

1. Install the Git, Docker Pipeline, and Credentials Binding plugins.
2. Add Docker Hub credentials in **Manage Jenkins → Credentials**.
3. Add any deployment credentials required by the pipeline in Jenkins Credentials.
4. Create a Pipeline job.
5. Configure the job to use the repository and its `Jenkinsfile`.
6. Run the pipeline and review the stage results and console output.

Use the credential IDs configured in your Jenkins instance in the `Jenkinsfile`. Never place the actual secret values in the pipeline script.

## CI/CD Pipeline Stages

The Jenkins pipeline is designed to perform these stages:

| Stage | Description |
|---|---|
| Checkout | Retrieves the latest source code from GitHub. |
| Build | Builds the Docker image from the project Dockerfile. |
| Tag | Applies a unique build number or Git SHA tag. |
| Push | Authenticates to Docker Hub using Jenkins credentials and pushes the image. |
| Deploy | Pulls the selected image and deploys it on the EC2 host. |
| Health Check | Checks that the container is running and healthy and that the application endpoint responds as expected. |
| Result / Rollback | Marks the build as successful or failed; invokes the configured rollback procedure if deployment validation fails. |

The exact stage implementation and rollback behavior are defined by the project's `Jenkinsfile`.

## GitHub Webhook

A GitHub webhook is used to trigger Jenkins after a repository push.

1. Configure the Jenkins job to accept the GitHub webhook trigger.
2. Add the Jenkins webhook endpoint in the GitHub repository's **Settings → Webhooks**.
3. Select the push event.
4. Save the webhook and verify its delivery status.
5. Push a test commit and confirm that Jenkins starts a new build automatically.

Use the webhook endpoint and configuration required by your Jenkins setup.

## Health Check & Deployment Validation

A deployment is considered successful only when all required validation checks pass.

On the EC2 instance:

```bash
docker ps
docker inspect --format='{{.State.Health.Status}}' <CONTAINER_NAME>
docker logs <CONTAINER_NAME>
```

Test the application endpoint from a machine that can reach the application:

```bash
curl -i http://<EC2_PUBLIC_IP>:<APP_PORT>/
```

Confirm that:

- The expected container is running.
- Docker reports the container as healthy, when a health check is configured.
- The application endpoint returns the expected HTTP response.
- The application logs do not show startup or runtime errors.

A running container alone does not prove that the application is working.

## Docker Resource Limits

The application container is configured with CPU and memory limits appropriate to the EC2 instance and application requirements.

Example command (adjust the values to match the instance capacity and workload):

```bash
docker run -d \
  --name kanban-dashboard \
  --memory=<MEMORY_LIMIT> \
  --cpus=<CPU_LIMIT> \
  -p <APP_PORT>:<APP_PORT> \
  <DOCKERHUB_USERNAME>/kanban-dashboard:<VERSION>
```

Verify the configured limits:

```bash
docker inspect --format='Memory={{.HostConfig.Memory}} NanoCpus={{.HostConfig.NanoCpus}}' kanban-dashboard
docker stats kanban-dashboard
```

Document why the selected limits are suitable for the EC2 instance. Do not copy example values without checking the available host resources.

## Logging & Monitoring

Useful commands for troubleshooting and evidence collection:

```bash
# Show running containers
docker ps

# View application container logs
docker logs <CONTAINER_NAME>

# Inspect container configuration and health
docker inspect <CONTAINER_NAME>

# Monitor live resource usage
docker stats
```

In Jenkins, retain and review:

- Build history.
- Console output for successful builds.
- Console output for failed builds.
- Stage-level results and the reason for any failed deployment.

## Evidence / Deliverables

Capture the following evidence for project demonstration or evaluation:

- Application running locally before Dockerization.
- Successful Docker image build.
- Dockerfile and `.dockerignore`.
- Non-root user configuration.
- Versioned image tag visible in Docker Hub.
- Image successfully pulled on EC2.
- Jenkins pipeline showing each stage.
- GitHub webhook delivery and automatic build trigger.
- Running container and Docker health status.
- Successful application `curl` response.
- Container CPU and memory limits.
- Jenkins pass and fail build console outputs.
- Docker logs and inspection output.

## Troubleshooting

| Problem | Checks |
|---|---|
| Jenkins job does not start after a push | Check webhook URL, delivery status, job trigger configuration, and Jenkins reachability. |
| Docker build fails | Review the Dockerfile, build context, `.dockerignore`, and dependency installation logs. |
| Docker Hub push fails | Check the image tag and Jenkins registry credentials. |
| Container exits | Review `docker logs` and inspect the container configuration. |
| Health check fails | Confirm the health-check command, application startup, and listening port. |
| Application cannot be reached | Check port mapping, application bind address, EC2 security-group rules, and host firewall. |
| Container uses too many resources | Review `docker stats`, host capacity, and configured CPU/memory limits. |

## Author / Project Information

- **Project:** Deploy Your Code on a Docker Container Using Jenkins on AWS
- **Application:** Kanban Dashboard
- **Source repository:** https://github.com/Vennilavanguvi/kanban-dashboard.git
- **Deployment platform:** AWS EC2
- **CI/CD:** Jenkins
- **Containerization:** Docker
- **Registry:** Docker Hub

---

**Note:** Replace placeholders such as `<APP_PORT>`, `<EC2_PUBLIC_IP>`, `<DOCKERHUB_USERNAME>`, `<VERSION>`, `<CONTAINER_NAME>`, `<MEMORY_LIMIT>`, and `<CPU_LIMIT>` with the actual values used in your environment. Keep credentials and private infrastructure details out of this README before publishing it publicly.
