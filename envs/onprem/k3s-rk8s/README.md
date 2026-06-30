# onprem / k3s-rk8s

rk8s feature environment: **rk8s.xuanwu.openatom.cn** (`mega-rk8s` namespace).

See [../README.md](../README.md) for cluster access, DNS, and rollout commands.
Copy `terraform.tfvars.example` to `terraform.tfvars` and set `rails_master_key`
before first apply.

```bash
cd envs/onprem/k3s-rk8s
terraform init && terraform plan && terraform apply
```
