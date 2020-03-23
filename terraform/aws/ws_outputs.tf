output "workstation_public_ips" {
  value = ["${aws_instance.workstation.*.public_ip}"]
}
output "workstation_vpc_id" {
  value = "${aws_vpc.habmgmt-vpc.id}"
}

output "workstation_security-group" {
  value = ["${aws_security_group.habworkshop.id}"]
}
output "workstation_subnet_id" {
  value = "${aws_subnet.habmgmt-subnet-a.id}"
}
