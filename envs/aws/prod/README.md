
当ec2 创建成功时，使用ssh 命令登录ec2 并在 /mnt/efs 目录下手动添加config.toml 配置文件

```bash
ssh -i ../../../../modules/compute/aws/ec2_ssh_key/gitmono-orion-key.pem orion@$(terraform output -raw gitmono_orion_public_ip)
```

在envs/dev 下创建 terraform.tfvars 并填入数据库用户名和密码字段

```bash
db_username = "gitmega"
db_password = "password"
```

当创建完资源后，如果terraform 不再管理这些资源，需要删除state

``` bash
terraform state list | while read r; do terraform state rm "$r"; done
```
