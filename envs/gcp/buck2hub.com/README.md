```bash
terraform apply

# The VM's metadata is provisioned with the public key from `tls_private_key.orion_vm_key` (ED25519).
# Use the generated key file, not a manually created RSA `orion.pem`.
ssh -o IdentitiesOnly=yes -i ./orion_vm_ed25519 ubuntu@$(terraform output -raw orion_vm_public_ip)
# or:
# ssh -o IdentitiesOnly=yes -i ./orion_vm_ed25519 orion@$(terraform output -raw orion_vm_public_ip)


```