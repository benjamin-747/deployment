# onprem / k3s (default)

Default gitmono stack for **xuanwu.openatom.cn**. See [../README.md](../README.md) for
the three-environment overview (rk8s / rust siblings).

## What it deploys

- Namespace `buck2hub`
- **5 gitmono apps** with Traefik Ingress per subdomain
- In-cluster **PostgreSQL / MySQL / Redis / RustFS** (`longhorn` PVC)

Implementation is delegated to `modules/compute/kubernetes/gitmono_stack`.

## Connecting to the cluster (openatom-1)

The target cluster lives behind NAT — its API server isn't exposed on the
public IP, so we reach it through an SSH tunnel and keep the kubeconfig pointing
at `127.0.0.1:6443` (which is in the k3s serving cert's SAN list).

1. Fetch credentials from the server (already done once into `~/.kube/k3s.yaml`):
   ```bash
   ssh openatom-1 'sudo cat /etc/rancher/k3s/k3s.yaml' > ~/.kube/k3s.yaml
   chmod 600 ~/.kube/k3s.yaml
   ```
2. Open the tunnel (leave it running while you use Terraform/kubectl).

   Use the dedicated `k3s-tunnel` alias in `~/.ssh/config` — it carries
   keepalive options (`ServerAliveInterval`/`ServerAliveCountMax`) and
   `ExitOnForwardFailure`, so a dropped link makes ssh exit cleanly instead of
   leaving a half-dead listener that silently hangs `kubectl`/`terraform`:
   ```bash
   # If this prints "ok", an existing local listener is already usable.
   KUBECONFIG=~/.kube/k3s.yaml kubectl --request-timeout=5s get --raw=/readyz

   # Otherwise clean up the alias-launched tunnel and reopen it.
   pkill -f '[s]sh .*k3s-tunnel|[s]sh .*-L 6443:127.0.0.1:6443' || true
   ssh -f -N k3s-tunnel
   ```

   > The bare `ssh -f -N -L 6443:127.0.0.1:6443 openatom-1` form has **no
   > keepalive**: after sleep/network changes the tunnel goes stale, the local
   > :6443 listener stays up, and every request through it hangs forever.
   > If `ssh -f -N k3s-tunnel` says `Address already in use`, do not start a
   > second tunnel. Either the existing listener is healthy, or it is stale and
   > should be killed by matching the SSH tunnel process: `pkill -f '[s]sh .*k3s-tunnel|[s]sh .*-L 6443:127.0.0.1:6443'; ssh -f -N k3s-tunnel`

3. Sanity check:
   ```bash
   export KUBECONFIG=~/.kube/k3s.yaml
   kubectl get nodes
   kubectl get ingressclass   # expect: traefik
   ```

## Usage

```bash
cd envs/onprem/k3s
$EDITOR terraform.tfvars

terraform init
terraform plan
terraform apply
```

Verify:

```bash
export KUBECONFIG=~/.kube/k3s.yaml
kubectl -n buck2hub get pods,svc,ingress
```

Roll out new images:

```bash
export KUBECONFIG=~/.kube/k3s.yaml
kubectl -n buck2hub rollout restart deployment/mono-engine deployment/mega-ui \
  deployment/mega-web-sync deployment/orion-server deployment/campsite-api
```

Tear down:

```bash
terraform destroy
```

## Key variables

See `variables.tf` and `terraform.tfvars`. Important knobs:

| Variable | This env |
|----------|----------|
| `namespace` | `buck2hub` |
| `base_domain` | `xuanwu.openatom.cn` |
| `app_images` | Per-service full image refs |
| `cors_allowed_origins` | UI origins for mono-engine / orion-server |
| `cratespro_url` | Shared global cratespro URL (default unchanged) |

## Notes

- State is local by default (`terraform.tfstate` in this directory).
- After changing `rustfs_access_key` / `rustfs_secret_key`, the module rolls RustFS via a pod-template checksum annotation.
