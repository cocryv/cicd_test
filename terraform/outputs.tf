# =============================================================================
# OUTPUTS - GCP CI/CD Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# GKE Cluster Outputs
# -----------------------------------------------------------------------------

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint for GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate for GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "gke_connection_command" {
  description = "Command to connect to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}

# -----------------------------------------------------------------------------
# Jenkins Outputs
# -----------------------------------------------------------------------------

output "jenkins_external_ip" {
  description = "External IP address of Jenkins server"
  value       = google_compute_address.jenkins_ip.address
}

output "jenkins_url" {
  description = "URL to access Jenkins"
  value       = "http://${google_compute_address.jenkins_ip.address}:8080"
}

output "jenkins_ssh_command" {
  description = "Command to SSH into Jenkins server"
  value       = "gcloud compute ssh jenkins-server --zone ${var.zone} --project ${var.project_id}"
}

output "jenkins_initial_password_command" {
  description = "Command to get Jenkins initial admin password"
  value       = "gcloud compute ssh jenkins-server --zone ${var.zone} --project ${var.project_id} --command 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
}

# -----------------------------------------------------------------------------
# Artifact Registry Outputs
# -----------------------------------------------------------------------------

output "artifact_registry_url" {
  description = "URL of the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.name}"
}

output "docker_push_command_example" {
  description = "Example command to push a Docker image"
  value       = "docker push ${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.name}/IMAGE_NAME:TAG"
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

# -----------------------------------------------------------------------------
# Service Account Outputs
# -----------------------------------------------------------------------------

output "jenkins_service_account_email" {
  description = "Email of the Jenkins service account"
  value       = google_service_account.jenkins_sa.email
}

output "gke_service_account_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_sa.email
}
