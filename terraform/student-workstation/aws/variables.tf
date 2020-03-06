
////////////////////////////////
// AWS Connection

variable "aws_profile" {
  default = "default"
}
variable "aws_region" {
  default = "us-west-2"
}

////////////////////////////////
// Tags

variable "tag_customer" {}

variable "tag_project" {}

variable "tag_name" {
  default = "hab-win-ws"
}

variable "tag_dept" {}

variable "tag_contact" {}

variable "tag_application" {
  default = "hab-win-ws"
}

variable "tag_ttl" {}

variable "aws_key_pair_file" {}

variable "aws_key_pair_name" {}

variable "automate_hostname" {
  description = "automate_hostname is the hostname which will be given to your A2 instance"
}


////////////////////////////////
// Instance Configs

variable "count" {
  default = "1"
}
