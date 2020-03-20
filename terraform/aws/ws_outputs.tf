output "vpc_id" {
  value = "${aws_vpc.habmgmt-vpc.id}"
}

output "security-group" {
  value = ["${aws_security_group.habworkshop.id}"]
}
output "subnet_id" {
  value = "${aws_subnet.habmgmt-subnet-a.id}"
}

output "workstation_public_ips" {
  value = ["${aws_instance.workstation.*.public_ip}"]
}

