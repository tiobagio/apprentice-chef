resource "aws_instance" "workstation" {
  depends_on = [aws_instance.chef_automate]

  count                       = var.counter
  ami                         = data.aws_ami.windows_workstation.id
  instance_type               = "t3.large"
  key_name                    = var.aws_key_pair_name
  subnet_id                   = aws_subnet.habmgmt-subnet-a.id
  vpc_security_group_ids      = [aws_security_group.habworkshop.id]
  associate_public_ip_address = true

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }


    user_data = <<EOF
    <powershell>
    net user ${var.workstation_user} ${var.workstation_password} /add /y
    net localgroup administrators ${var.workstation_user} /add
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
    netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
    netsh advfirewall firewall add rule name="RDP 3389" protocol=TCP dir=in localport=3389 action=allow
    net stop winrm
    sc.exe config winrm start=auto
    net start winrm
    </powershell>
    EOF


  tags = {
    Name          = "${var.tag_contact}-workstation-${count.index}"
    X-Dept        = var.tag_dept
    X-Customer    = var.tag_customer
    X-Project     = var.tag_project
    X-Application = var.tag_application
    X-Contact     = var.tag_contact
    X-TTL         = var.tag_ttl
  }
}

resource "null_resource" "wait_for_mins" {
  depends_on = [aws_instance.workstation]
  ## This sleep is required to allow the Windows machine to be ready to accept the files.
  provisioner "local-exec" {
    command = "sleep 120"
  }
}

resource "null_resource" "key_user" {
  depends_on = [null_resource.wait_for_mins]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_user1}-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\Users\\chef\\${var.chef_user1}.pem"
      connection {
        host = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = var.workstation_user
        password = var.workstation_password
        insecure = true
        timeout = "10m"
      }
  }
}

resource "null_resource" "key_validator" {
  depends_on = [null_resource.wait_for_mins]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_organization}-validator-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\Users\\chef\\${var.chef_organization}.pem"
      connection {
          host = aws_instance.workstation[count.index].public_ip
          type     = "winrm"
          user     = var.workstation_user
          password = var.workstation_password
          insecure = true
          timeout = "10m"
        }
  }
}

resource "null_resource" "key_kitchen" {
  depends_on = [null_resource.wait_for_mins]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/.ssh/id_rsa"
      destination = "C:\\Users\\chef\\.ssh\\id_rsa"
      connection {
          host      = aws_instance.workstation[count.index].public_ip
          type      = "winrm"
          user      = var.workstation_user
          password  = var.workstation_password
          insecure  = true
          timeout   = "10m"
        }
  }
}

#    destination = "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\open_a2.ps1"
resource "null_resource" "open_a2" {
  depends_on = [null_resource.wait_for_mins]
  count = var.counter
  provisioner "file" {
    content      = templatefile("${path.module}/templates/open_a2.ps1.tpl", 
                { 
                var_automate_hostname = var.automate_hostname, 
                var_chef_user1 = var.chef_user1, 
                var_chef_organization = var.chef_organization
                })
    destination = "C:\\Users\\TEMP\\open_a2.ps1"
      connection {
          host      = aws_instance.workstation[count.index].public_ip
          type      = "winrm"
          user      = var.workstation_user
          password  = var.workstation_password
          insecure  = true
          timeout   = "10m"
        }
  }
}


resource "null_resource" "exec_open_a2" {
  depends_on = [null_resource.key_kitchen]
  count = var.counter
  provisioner "remote-exec" {
    inline = [
      "powershell -File \"C:\\Users\\TEMP\\open_a2.ps1\""
    ]
      connection {
        host     = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = var.workstation_user
        password = var.workstation_password
        insecure = true
        timeout  = "15m"
      }
  }
}
