当EC2创建成功后，使用SSH登录，并在 `/mnt/efs` 目录下手动添加 `config.toml` 配置文件。

```bash
ssh -i ../../../../modules/compute/aws/ec2_ssh_key/gitmega-orion-key.pem orion@$(terraform output -raw gitmega_orion_public_ip)
```
