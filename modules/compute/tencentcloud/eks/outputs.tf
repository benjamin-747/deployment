output "cluster_id" {
  description = "TKE cluster ID"
  value       = tencentcloud_kubernetes_cluster.this.id
}

output "serverless_node_pool_id" {
  description = "Serverless node pool ID"
  value       = tencentcloud_kubernetes_serverless_node_pool.this.id
}

output "kube_config" {
  description = "Kubeconfig for the cluster"
  value       = var.cluster_public_access ? tencentcloud_kubernetes_cluster_endpoint.public[0].kube_config : tencentcloud_kubernetes_cluster.this.kube_config
  sensitive   = true
}
