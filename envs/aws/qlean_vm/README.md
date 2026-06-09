# Qlean VM

## 销毁 VM

```bash
cd /Users/Yetianxing/workspace/mega-terraform/envs/aws/qlean_vm

# 销毁整个 VM（磁盘会一并删除，无法恢复）
terraform destroy -var-file=terraform.tfvars -auto-approve
```

> **注意**：磁盘配置为 `delete_on_termination = true`，销毁 VM 时 EBS 卷会同时删除，不保留快照。
