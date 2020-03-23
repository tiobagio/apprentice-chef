resource "aws_instance" "workstation" {
    depends_on = ["aws_instance.chef_automate"]

  connection {
    type     = "winrm"
    user     = "hab"
    password = "ch3fh@b1!"
  }

  count                       = "${var.count}"
  ami                         = "${data.aws_ami.windows_workstation.id}"
  instance_type               = "t3.large"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.habmgmt-subnet-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.habworkshop.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "testKitchenAndKnifeEc2"

  root_block_device {
    delete_on_termination = true
    volume_size           = 100
    volume_type           = "gp2"
  }


    user_data = <<EOF
    <powershell>
    net user chef RL9@T40BTmXh /add /y
    net localgroup administrators chef /add
    winrm quickconfig -q
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    netsh advfirewall firewall add rule name=”WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
    netsh advfirewall firewall add rule name=”WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
    netsh advfirewall firewall add rule name=”RDP 3389" protocol=TCP dir=in localport=3389 action=allow
    net stop winrm
    sc.exe config winrm start=auto
    net start winrm
    choco install googlechrome -y
    choco install vscode -y
    choco install cmder -y
    choco install git -y
    choco install notepad++ -y
    md C:\Chef
    md C:\Chef\.chef
    md C:\Chef\cookbooks
    md C:\Chef\roles
    New-Item -Path C:\Chef\.chef\ -Name "config.rb" -ItemType "file" -Value " "
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'current_dir = File.dirname(__FILE__)'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'log_level                :info'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'log_location             STDOUT'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'node_name                "${var.chef_user1}"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'client_key               "#{current_dir}/${var.chef_user1}.pem"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'chef_server_url          "https://${var.automate_hostname}/organizations/${var.chef_organization}"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'cookbook_path            ["#{current_dir}/../cookbooks"]'
    git config --global user.email "me@chef.io"
    git config --global user.name "Chef"
    </powershell>
    EOF


  tags {
    Name          = "${var.tag_contact}-workstation-${count.index}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }
}

resource "null_resource" "wait_for_mins" {
  depends_on = ["aws_instance.workstation"]
  ## This sleep is required to allow the Windows machine to be ready to accept the files.
  provisioner "local-exec" {
    command = "sleep 320"
  }
}

resource "null_resource" "key_user" {
  depends_on = ["null_resource.wait_for_mins"]
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_user1}-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\Chef\\.chef\\${var.chef_user1}.pem"
      connection {
        host = "${aws_instance.workstation.public_ip}"
        type     = "winrm"
        user     = "hab"
        password = "ch3fh@b1!"
        insecure = true
        timeout = "10m"
      }
  }

}

resource "null_resource" "key_validator" {
  depends_on = ["null_resource.wait_for_mins"]
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_organization}-validator-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\Chef\\.chef\\${var.chef_organization}.pem"
      connection {
          host = "${aws_instance.workstation.public_ip}"
          type     = "winrm"
          user     = "hab"
          password = "ch3fh@b1!"
          insecure = true
          timeout = "10m"
        }
  }
}

resource "null_resource" "key_kitchen" {
  depends_on = ["null_resource.wait_for_mins"]
  provisioner "file" {
      source      = "${var.key_path}/src/cookbooks/id_rsa"
      destination = "C:\\Users\\Chef\\.ssh\\id_rsa"
      connection {
          host = "${aws_instance.workstation.public_ip}"
          type     = "winrm"
          user     = "hab"
          password = "ch3fh@b1!"
          insecure = true
          timeout = "10m"
        }
  }
}

# resource "null_resource" "browser" {
#   provisioner "remote-exec" {
#     inline = [
#       "PowerShell.exe -Command \"start-process -FilePath 'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe -ArgumentList 'https://${var.automate_hostname}''\"",
#     ]
#       connection {
#         host = "${aws_instance.workstation.public_ip}"
#         type     = "winrm"
#         user     = "hab"
#         password = "ch3fh@b1!"
#         insecure = true
#         timeout = "10m"
#       }
#   }
# }
