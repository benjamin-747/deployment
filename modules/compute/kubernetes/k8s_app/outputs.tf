output "service_name" {
  description = "Kubernetes Service name (in-cluster DNS: <name>.<namespace>.svc.cluster.local)"
  value       = kubernetes_service_v1.this.metadata[0].name
}

output "cluster_ip" {
  description = "ClusterIP assigned to the Service"
  value       = kubernetes_service_v1.this.spec[0].cluster_ip
}

output "load_balancer_ip" {
  description = "External IP when service_type is LoadBalancer (empty otherwise)"
  value       = try(kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].ip, "")
}
