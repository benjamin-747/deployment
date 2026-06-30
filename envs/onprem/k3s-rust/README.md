# onprem / k3s-rust

rust feature environment: **rust.xuanwu.openatom.cn** (`mega-rust` namespace).

See [../README.md](../README.md) for cluster access, DNS, and rollout commands.
Copy `terraform.tfvars.example` to `terraform.tfvars` and set `rails_master_key`
before first apply.

```bash
cd envs/onprem/k3s-rust
terraform init && terraform plan && terraform apply
```
