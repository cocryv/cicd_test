# =============================================================================
# JENKINS VM CONFIGURATION
# =============================================================================

# -----------------------------------------------------------------------------
# Service Account for Jenkins
# -----------------------------------------------------------------------------

resource "google_service_account" "jenkins_sa" {
  account_id   = "jenkins-sa"
  display_name = "Jenkins Service Account"
  project      = var.project_id

  depends_on = [google_project_service.apis]
}

# Grant necessary permissions to Jenkins service account
resource "google_project_iam_member" "jenkins_sa_roles" {
  for_each = toset([
    "roles/container.developer",      # Access to GKE
    "roles/artifactregistry.writer",  # Push images
    "roles/compute.viewer",           # View compute resources
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# -----------------------------------------------------------------------------
# Static External IP for Jenkins
# -----------------------------------------------------------------------------

resource "google_compute_address" "jenkins_ip" {
  name    = "jenkins-external-ip"
  region  = var.region
  project = var.project_id

  depends_on = [google_project_service.apis]
}

# -----------------------------------------------------------------------------
# Jenkins VM Instance
# -----------------------------------------------------------------------------

resource "google_compute_instance" "jenkins" {
  name         = "jenkins-server"
  machine_type = var.jenkins_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = ["jenkins"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.jenkins_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name

    access_config {
      nat_ip = google_compute_address.jenkins_ip.address
    }
  }

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update
    apt-get upgrade -y

    # Install Java (required for Jenkins)
    apt-get install -y openjdk-17-jdk

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    apt-get install -y jenkins

    # Install Docker
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Add jenkins user to docker group
    usermod -aG docker jenkins

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Install gcloud CLI
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update
    apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin

    # Configure Docker to use gcloud for Artifact Registry
    gcloud auth configure-docker ${var.region}-docker.pkg.dev --quiet

    # Start Jenkins
    systemctl enable jenkins
    systemctl start jenkins

    # Wait for Jenkins to start and get initial admin password
    sleep 30
    echo "Jenkins initial admin password:" >> /var/log/jenkins-setup.log
    cat /var/lib/jenkins/secrets/initialAdminPassword >> /var/log/jenkins-setup.log 2>/dev/null || echo "Password file not yet available" >> /var/log/jenkins-setup.log

    echo "Jenkins setup complete!"
  EOF

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    app         = "jenkins"
  }

  allow_stopping_for_update = true

  depends_on = [
    google_project_service.apis,
    google_compute_subnetwork.subnet,
  ]
}
