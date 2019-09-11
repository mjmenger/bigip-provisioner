# main GCP BIGIP provisioning module
# presumes that the provider is initialized in the caller

# information found at 
# https://github.com/F5Networks/f5-google-gdm-templates/blob/master/supported/standalone/1nic/
data "google_compute_image" "my_image" {
  name      = "f5-bigip-14-1-0-3-0-0-6-payg-best-5gbps-190329165642"
  project   = "f5-7626-networks-public" # f5 public project
}