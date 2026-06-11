# k3s exposes a standard Kubernetes API. Point both providers at the kubeconfig
# copied from the k3s server (/etc/rancher/k3s/k3s.yaml).
#
# When running Terraform from a different host than the k3s server, edit the
# kubeconfig so `server:` uses the server's real IP/DNS instead of 127.0.0.1,
# and make sure the cluster was installed with `--tls-san <that IP/DNS>`.

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kubeconfig_context
  }
}
