output "bigip_instance_dns" {
  value = "${aws_instance.f5bigip.*.public_dns}"
  description = "The public dns name of the bigip instance"
}

output "bigip_admin_password" {
  value     = "${random_string.bigippassword.result}"
  # sensitive = true
}
