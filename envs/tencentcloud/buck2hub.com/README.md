# Tencent Cloud — buck2hub.com

Tencent Cloud environment modeled on the AWS `gitmono.com` stack.

Status: network / security / storage / CLB modules are implemented with real
resources. The compute module provisions TKE Serverless (managed TKE cluster +
serverless node pool) and deploys the gitmono services as Kubernetes Deployments
and Services via the `kubernetes` provider (gated by `enable_workloads`).

## Structure

```
envs/tencentcloud/buck2hub.com/
├── main.tf                  # Wires modules in deployment order
├── variables.tf             # Environment variables
├── providers.tf             # tencentcloud provider config
├── versions.tf              # Provider version constraints + COS backend (commented)
├── terraform.tfvars.example # Example variable values
└── README.md
```

## Module mapping (AWS gitmono.com -> Tencent Cloud)


| AWS module                            | Tencent Cloud module                                | Status      |
| ------------------------------------- | --------------------------------------------------- | ----------- |
| `modules/network/aws/vpc`             | `modules/network/tencentcloud/vpc`                  | implemented |
| `modules/security/aws/security_group` | `modules/security/tencentcloud/security_group`      | implemented |
| `modules/security/aws/acm`            | `modules/security/tencentcloud/ssl_certificate`     | skeleton    |
| `modules/storage/aws/rds`             | `modules/storage/tencentcloud/postgresql`           | implemented |
| S3 (inline)                           | `modules/storage/tencentcloud/cos`                  | implemented |
| `modules/storage/aws/valkey`          | `modules/storage/tencentcloud/redis`                | implemented |
| `modules/compute/aws/ecs` (Fargate)   | `modules/compute/tencentcloud/eks` (TKE Serverless) | implemented |
| `modules/compute/aws/alb`             | `modules/compute/tencentcloud/clb`                  | implemented |


## Quick start

```bash
cd envs/tencentcloud/buck2hub.com
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

export TF_VAR_tencentcloud_secret_id="your-secret-id"
export TF_VAR_tencentcloud_secret_key="your-secret-key"

terraform init

# Step 1: create infra (cluster + storage). Keep enable_workloads = false.
terraform apply

# Step 2: deploy gitmono workloads. The kubernetes provider can only connect once
# the cluster exists, so flip the toggle and apply again.
terraform apply -var 'enable_workloads=true'   # or set it in terraform.tfvars
```

## gitmono workloads

`module.workloads` creates one Deployment + Service per gitmono service
(mono-engine, mega-ui, web-sync, orion-server, campsite-api). Env vars are built
in `main.tf` locals and point at the Tencent Cloud PostgreSQL / Redis / COS
endpoints created in this stack. Services stay `ClusterIP`; public access uses
**scheme B** (one shared CLB + host-based routing).

## Public access (scheme B: shared CLB)

One public CLB (`module.clb`) fronts all services. Each hostname gets a listener
rule with `NODE` backends; pod ENI IPs are bound via `tencentcloud_clb_attachment`
in `clb_backends.tf` when `enable_workloads=true`. (CLB target groups are beta
and not enabled on all accounts, so we avoid `CreateTargetGroup`.)

| Host | Backend port |
| ---- | ------------ |
| `git.<base_domain>` | 8000 (mono-engine) |
| `app.<base_domain>` | 3000 (mega-ui) |
| `sync.<base_domain>` | 9000 (mega-web-sync) |
| `orion.<base_domain>` | 8004 (orion-server) |
| `api.<base_domain>` | 8080 (campsite-api) |

**DNS:** CNAME each host to `terraform output -raw clb_domain` (or A records to
`clb_vips`). Until the SSL certificate module is implemented, traffic uses the
HTTP listener (port 80).

**Apply order:**

```bash
terraform apply                                    # CLB + listener rules
terraform apply -var 'enable_workloads=true' -parallelism=1   # pods + CLB backends
```

If pods restart and get new IPs, run the workloads apply again to refresh CLB
backend registrations.

## EKSCI pilot (mega-ui)

Deploy **mega-ui** as a [容器实例 EKSCI](https://cloud.tencent.com/document/product/457/57339)
instead of a TKE Pod — no Kubernetes cluster required for this service.

```bash
# Infra + CLB must exist first (enable_workloads can stay false).
terraform apply -var 'enable_eksci_test=true'
```

- `app.<base_domain>` CLB rule targets the instance **private IP** on port 3000.
- `enable_pod_eip` also controls EKSCI auto-created EIP (image pull / egress).
- When `enable_eksci_test=true`, mega-ui is **not** scheduled on TKE even if
  `enable_workloads=true`.

```bash
terraform output eksci_mega_ui
```

## Kubernetes provider: Unexpected Identity Change

If an apply to deploy workloads is interrupted (e.g. TKE public API `EOF` /
`connection reset by peer`), Terraform may leave Kubernetes resources in state with
a **null identity** (`api_version` / `kind` / `name` / `namespace` all null).
The next plan/apply then fails with:

```text
Error: Unexpected Identity Change
Current Identity: api_version=null, kind=null, name=null, namespace=null
New Identity:   api_version="apps/v1", kind="Deployment", name="...", namespace="default"
```

### Fix

1. **Always pass `-var 'enable_workloads=true'`** when repairing or deploying
  workloads. Without it, `module.workloads` has an empty `for_each` and Terraform
   will plan to **destroy** every workload still in state.
2. For each affected Deployment, remove the broken state entry and re-import the
  live object (Service resources are less often affected):

```bash
cd envs/tencentcloud/buck2hub.com

# Example: mono-engine Deployment
terraform state rm 'module.workloads["mega_ui"].kubernetes_deployment_v1.this'
terraform import 'module.workloads["mega_ui"].kubernetes_deployment_v1.this' default/mega-ui

# Repeat for other services if needed (k8s name uses hyphens):
#   mega_web_sync  -> default/mega-web-sync
#   orion_server   -> default/orion-server
#   campsite_api   -> default/campsite-api
#   mega_ui        -> default/mega-ui
```

1. If import fails with `EOF` / `connection reset`, retry — the public API link
  is intermittent. Use a stable network or bypass local proxy/TUN for
   `*.clb.hk-tencentclb.com`.
2. Verify before apply:

```bash
terraform plan -var 'enable_workloads=true'
```

Expect only missing resources to be **added**, not existing workloads **destroyed**.

1. Finish deployment:

```bash
terraform apply -var 'enable_workloads=true' -parallelism=1
```

`-parallelism=1` reduces concurrent Kubernetes API calls when the public endpoint
is unstable.

## Notes

- Tencent Cloud has no Internet Gateway resource; subnets reach the internet via
public IP / EIP (or a NAT gateway for private subnets).
- Container images default to the AWS ECR Public repo (`public.ecr.aws/m8q5m4u3/mega`).
Super (serverless) nodes need internet egress to pull them; otherwise mirror the images
into Tencent Cloud TCR/CCR and override `image_repo_base`.
- COS is S3-compatible; use the virtual-hosted endpoint
`https://<bucket>.cos.<region>.myqcloud.com` (`module.cos.bucket_url`). Path-style
`https://cos.<region>.myqcloud.com/<bucket>` returns `403 PathStyleDomainForbidden`.
- The cluster exposes a public API endpoint (`cluster_public_access = true`) so Terraform can
manage workloads. Access is restricted by the environment security group — tighten its 443
ingress for production.
- The SSL certificate module is still a skeleton; the CLB HTTPS listener is created
only when `certificate_id` is provided.
- Enable the COS backend in `versions.tf` once a state bucket exists.

