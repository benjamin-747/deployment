## Install Terraform

If you use a package manager on macOS, Windows, or Linux, you can use it to install Terraform.

First, install the HashiCorp tap (official Homebrew repository):

```bash
brew tap hashicorp/tap
```

Install Terraform:

```bash
brew install hashicorp/tap/terraform
```

Check your Terraform version:

```bash
terraform -version
```

## Write configuration

Terraform configuration files are plain text files written in HashiCorp Configuration Language (HCL) and end with `.tf`.

We recommend using consistent formatting. Run:

```bash
terraform fmt
```

## Initialize your workspace

Before applying, initialize the working directory so Terraform can download and install providers:

```bash
terraform init
```

Validate your configuration:

```bash
terraform validate
```

## Apply infrastructure

Terraform applies changes in two steps: create an execution plan, then apply it.

Terraform creates an execution plan for the changes it will make. Review this plan to ensure that Terraform will make the changes you expect.

Once you approve the execution plan, Terraform applies those changes using your workspace's providers.

This workflow ensures that you can detect and resolve any unexpected problems with your configuration before Terraform makes changes to your infrastructure.

```bash
cd deployment/envs/gcp/prod
terraform plan -out tf.plan
terraform apply tf.plan
```

## GCP Deployment (dev / staging / prod)

Terraform configurations for deploying Mega to GCP are under:

- `deployment/envs/gcp/prod`

Each environment directory contains:

- `main.tf`
- `variables.tf`
- `providers.tf`
- `versions.tf`
- `terraform.tfvars.example`

### Prerequisites

- Install `gcloud` and authenticate to the target project.
- Ensure you have permissions to create: VPC, Cloud Run, Cloud SQL, Memorystore (Redis), Filestore, GCS, IAM, Cloud Logging/Monitoring.

Recommended API enablement:

```bash
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  sqladmin.googleapis.com \
  servicenetworking.googleapis.com \
  redis.googleapis.com \
  file.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com
```

### Configure variables

Copy the example file and edit values:

```bash
cd deployment/envs/gcp/prod
cp terraform.tfvars.example terraform.tfvars
```

Sensitive values should be provided via environment variables when using CI/CD:

```bash
export TF_VAR_db_username="mega_user"
export TF_VAR_db_password="your-db-password"
export TF_VAR_rails_master_key="your-rails-master-key"
```

### Apply

```bash
terraform init
terraform plan
terraform apply
```

### Outputs

Example outputs after deployment:

- `app_cloud_run_url` – Cloud Run backend (mono) URL
- `ui_cloud_run_url` – Cloud Run UI (Next.js SSR) URL
- `cloud_sql_connection_name` – Cloud SQL connection name for the application

### Images (ECR Public -> Cloud Run)

- backend (mono): `public.ecr.aws/m8q5m4u3/mega:mono-0.1.0-pre-release`
- UI (Next.js): `public.ecr.aws/m8q5m4u3/mega:mega-ui-<env>-0.1.0-pre-release` (e.g. `staging`, `demo`, `openatom`, `gitmono`)

Notes:

- Pulling images from ECR Public does not require additional Terraform resources; just set `app_image` / `ui_image` in `terraform.tfvars`.
- If you need more stable pulls and better in-region performance, you can mirror images into GCP Artifact Registry and switch `app_image` / `ui_image` to Artifact Registry URLs.

### Verify logging & monitoring

Cloud Run stdout/stderr is exported to Cloud Logging by default. You can verify in Cloud Console:

- Logging: Logs Explorer (resource type `cloud_run_revision`)
- Monitoring: Cloud Run dashboards

### Destroy / rollback

```bash
terraform destroy
```

## Inspect state

Terraform stores infrastructure state in `terraform.tfstate`.

List tracked resources:

```bash
terraform state list
```

Print the full state:

```bash
terraform show
```
