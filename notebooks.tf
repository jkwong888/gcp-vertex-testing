data "google_compute_zones" "available" {
    project = module.service_project.project_id
    region = var.region
}

resource "google_compute_subnetwork_iam_member" "notebooks_network_user" {
    depends_on = [
        module.service_project.enabled_apis

    ]
    subnetwork = module.service_project.subnets[0].id
    role = "roles/compute.networkUser"
    member = "serviceAccount:service-${module.service_project.number}@gcp-sa-notebooks.iam.gserviceaccount.com"
}

resource "google_service_account" "notebook" {
    project = module.service_project.project_id
    account_id = "notebook"
}

resource "google_project_iam_member" "notebook_storage_admin" {
    project = module.service_project.project_id
    role = "roles/storage.admin"
    member = "serviceAccount:${google_service_account.notebook.email}"
}

resource "google_project_iam_member" "notebook_aiplatform_user" {
    project = module.service_project.project_id
    role = "roles/aiplatform.user"
    member = "serviceAccount:${google_service_account.notebook.email}"
}

resource "google_service_account_iam_member" "notebook_sa_user" {
    service_account_id = google_service_account.notebook.id
    role = "roles/iam.serviceAccountUser"
    member = "serviceAccount:${google_service_account.notebook.email}"
}

resource "google_notebooks_instance" "instance" {
  project = module.service_project.project_id

  name = "tensorflow-jupyter"

  location = data.google_compute_zones.available.names[0]
  machine_type = "n1-standard-2"
  vm_image {
    project      = "deeplearning-platform-release"
    image_family = "tf-ent-2-8-cpu"
  }

  network = data.google_compute_network.shared_vpc.id
  subnet = module.service_project.subnets[0].id

  service_account = google_service_account.notebook.email
  no_public_ip = true

}