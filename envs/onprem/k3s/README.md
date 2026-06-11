# onprem / k3s

Terraform environment for managing workloads on a self-hosted **k3s** cluster
(a lightweight, fully conformant Kubernetes distribution). k3s exposes the
standard Kubernetes API, so this env uses the generic `hashicorp/kubernetes`
and `hashicorp/helm` providers — no cloud SDK required.

## What it deploys

A minimal, self-contained example so you can verify connectivity end-to-end:

- a `demo` Namespace
- an nginx Deployment (2 replicas, with a readiness probe)
- a ClusterIP Service (switch `service_type` to NodePort/LoadBalancer if needed)
- a **Traefik Ingress** routing the public host to the Service
- the **5 gitmono apps** (mono-engine, mega-ui, mega-web-sync, orion-server, campsite-api)
- in-cluster **PostgreSQL / MySQL / Redis** (Bitnami Helm, `longhorn` PVC)
- (optional) a `bitnami/nginx` Helm release to exercise the helm provider

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

   <details><summary>The <code>k3s-tunnel</code> ssh config block</summary>

  ```sshconfig
   Host k3s-tunnel
     HostName 39.155.148.152
     Port 22101
     User root
     LocalForward 6443 127.0.0.1:6443
     ServerAliveInterval 20
     ServerAliveCountMax 3
     ExitOnForwardFailure yes
     TCPKeepAlive yes
  ```
   </details>
3. Sanity check:
  ```bash
   export KUBECONFIG=~/.kube/k3s.yaml
   kubectl get nodes
   kubectl get ingressclass   # expect: traefik
  ```

## Usage

```bash
cd envs/onprem/k3s

# adjust ingress_host / service settings as needed
$EDITOR terraform.tfvars

terraform init
terraform plan      # review carefully — this is a shared, live cluster
terraform apply
```

Verify:

```bash
export KUBECONFIG=~/.kube/k3s.yaml
kubectl -n demo get pods,svc,ingress

# Traefik listens on the node's :80; spoof the Host header to test:
curl --resolve hello.k3s.local:80:172.16.121.101 http://hello.k3s.local/
```

Tear down:

```bash
terraform destroy
```

## Variables


| Variable              | Default             | Description                                  |
| --------------------- | ------------------- | -------------------------------------------- |
| `kubeconfig_path`     | `~/.kube/k3s.yaml`  | Path to the k3s kubeconfig                   |
| `kubeconfig_context`  | `default`           | kubeconfig context to use                    |
| `namespace`           | `demo`              | Namespace for the example workload           |
| `app_name`            | `hello-nginx`       | Name of the Deployment/Service               |
| `image`               | `nginx:1.27-alpine` | Container image                              |
| `container_port`      | `80`                | Container port                               |
| `replicas`            | `2`                 | Pod replicas                                 |
| `service_type`        | `ClusterIP`         | `ClusterIP`, `NodePort` or `LoadBalancer`    |
| `node_port`           | `0`                 | Fixed NodePort (0 = auto-assign)             |
| `enable_ingress`      | `true`              | Create a Traefik Ingress for the example app |
| `ingress_class_name`  | `traefik`           | IngressClass (k3s default is `traefik`)      |
| `ingress_host`        | `hello.k3s.local`   | Host header the Ingress matches              |
| `ingress_path`        | `/`                 | Path prefix routed to the Service            |
| `enable_helm_example` | `false`             | Also install the `bitnami/nginx` Helm chart  |


## Notes

- k3s bundles **ServiceLB (Klipper)**, so `service_type = "LoadBalancer"` also
works out of the box on bare metal and assigns the node's IP.
- k3s also bundles **Traefik** as the default Ingress controller if you prefer
Ingress over NodePort.
- State is local by default. Wire up a remote backend before sharing this env
across a team.

