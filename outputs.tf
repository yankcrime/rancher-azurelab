output "control_nodes" {
  value = module.rke-control.nodes
}

output "worker_nodes" {
  value = module.rke-worker.nodes
}

output "all_nodes" {
  value = module.rke-all.nodes
}
