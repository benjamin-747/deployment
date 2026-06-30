# onprem / k3s environments

Three isolated **gitmono** stacks on a shared self-hosted **k3s** cluster. Each
environment is a separate Terraform root with its own state, namespace, datastores,
and public hostnames under a distinct `base_domain`.

## Environments

| Env | Directory | Namespace | base_domain | UI URL |
|-----|-----------|-----------|-------------|--------|
| default | [k3s](k3s) | `buck2hub` | `xuanwu.openatom.cn` | https://app.xuanwu.openatom.cn |
| rk8s | [k3s-rk8s](k3s-rk8s) | `mega-rk8s` | `rk8s.xuanwu.openatom.cn` | https://app.rk8s.xuanwu.openatom.cn |
| rust | [k3s-rust](k3s-rust) | `mega-rust` | `rust.xuanwu.openatom.cn` | https://app.rust.xuanwu.openatom.cn |

Each stack deploys the same 5 apps (`mono-engine`, `mega-ui`, `mega-web-sync`,
`orion-server`, `campsite-api`) plus in-cluster PostgreSQL, MySQL, Redis, and
RustFS. Hostnames follow `<prefix>.<base_domain>` (e.g. `git.rk8s.xuanwu.openatom.cn`).

Shared implementation: [modules/compute/kubernetes/gitmono_stack](../../modules/compute/kubernetes/gitmono_stack).

## Connecting to the cluster

All three roots share one kubeconfig and SSH tunnel. See [k3s/README.md](k3s/README.md#connecting-to-the-cluster-openatom-1).

```bash
export KUBECONFIG=~/.kube/k3s.yaml
kubectl get nodes
```

## Deploy / upgrade one environment

```bash
cd envs/onprem/k3s          # or k3s-rk8s / k3s-rust
$EDITOR terraform.tfvars    # per-env images, secrets, base_domain
terraform init
terraform plan
terraform apply
```

Roll out new images for that namespace only:

```bash
export KUBECONFIG=~/.kube/k3s.yaml
NS=mega-rk8s   # or buck2hub / mega-rust
kubectl -n "$NS" rollout restart deployment/mono-engine deployment/mega-ui \
  deployment/mega-web-sync deployment/orion-server deployment/campsite-api
```

## DNS (xuanwu gateway)

Point each environment's hosts at the upstream gateway (wildcard recommended):

- `*.xuanwu.openatom.cn` (existing)
- `*.rk8s.xuanwu.openatom.cn`
- `*.rust.xuanwu.openatom.cn`

`cratespro` is shared globally: `https://cratespro.xuanwu.openatom.cn` (all three UI stacks).

## Per-environment secrets

Before first `apply` on **rk8s** or **rust**, set in `terraform.tfvars`:

- `rails_master_key` — independent per environment (Rails encrypted credentials)
- `rustfs_access_key` / `rustfs_secret_key` — independent console + S3 credentials
- Database passwords — can match or differ; DB **names** must be unique per env

Use `terraform.tfvars.example` in each directory as a template.

## State

Local state per root by default:

- `envs/onprem/k3s/terraform.tfstate`
- `envs/onprem/k3s-rk8s/terraform.tfstate`
- `envs/onprem/k3s-rust/terraform.tfstate`

Wire up a remote backend before team-wide use.
