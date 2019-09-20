##### REQUIRED VARIABLES #####

variable "bigip_vpc" {
    description = "AWS VPC where the bigip will reside"
}

variable "bigip_region" {
    description = "AWS region where the bigip will reside"
}

variable "sshkeyname" {
    description = "name of AWS key pair to be used for authentication"
}

variable "sshkeypath" {
    description = "path to private key of key pair to be used for authentication"
}

##### OPTIONAL VARIABLES #####
variable "bigipcount" {
    default     = 1
    description = "number of bigip instances to create"
}


# map of the pay as you go bigip amis in each region
variable "bigipami" {
  type = "map"

  default = {
    us-east-2 = "ami-05bcf0af3e6efd689"
  }
}
# required for non-pool licensing
# currently pool licenses are not supported
variable "bigiplicense" {
  default = ""
  description = "the license to enable functionality of your brand new BIGIP!!!"
}

variable "waitformgmtintf"{
  default = 120
  description = "the duration in seconds to wait for the bigip management interface to become available"
}

variable "declarativeonboardingpackage" {
  default = "f5-declarative-onboarding-1.5.0-11.noarch.rpm"
  description = "the package to use to install the declarative onboarding service"
}

variable "declarativeonboardingpackagetarget" {
  default = "/var/config/rest/downloads/"
  description = "location on target machine where module installers will be placed"
}

## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable DO_onboard_URL	{ 
  default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.7.0/f5-declarative-onboarding-1.7.0-3.noarch.rpm" 
}
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
# always point to a specific version in order to avoid inadvertent configuration inconsistency
variable AS3_URL {
  default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.14.0/f5-appsvcs-3.14.0-4.noarch.rpm" 
}

variable "libs_dir" {
  default = "/config/cloud/aws/node_modules"
}

variable onboard_log { 
  default = "/var/log/startup-script.log" 
}