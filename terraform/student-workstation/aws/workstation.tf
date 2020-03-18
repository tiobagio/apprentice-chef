resource "aws_instance" "workstation" {

  connection {
    type     = "winrm"
    user     = "hab"
    password = "ch3fh@b1!"
  }

  count                       = "${var.count}"
  ami                         = "${data.aws_ami.windows_workstation.id}"
  instance_type               = "t3.large"
  key_name                    = "${var.aws_key_pair_name}"
  subnet_id                   = "${aws_subnet.habworkshop-subnet.id}"
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
    md C:\Chef
    md C:\Chef\.chef
    md C:\Chef\cookbooks
    md C:\Chef\roles
    New-Item -Path C:\Chef\.chef\ -Name "config.rb" -ItemType "file" -Value " "
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'current_dir = File.dirname(__FILE__)'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'log_level                :info'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'log_location             STDOUT'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'node_name                "anthony"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'client_key               "#{current_dir}/anthony.pem"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'chef_server_url          "https://${var.automate_hostname}/organizations/reesyorg"'
    Add-Content -Path C:\Chef\.chef\config.rb -Value 'cookbook_path            ["#{current_dir}/../cookbooks"]'
    </powershell>
    EOF


  tags {
    Name          = "${var.tag_contact}-${var.tag_customer}-habworkshop-${count.index}"
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
    command = "sleep 280"
  }
}

## Set Keys
resource "null_resource" "key_user" {
  depends_on = ["null_resource.wait_for_mins"]
  provisioner "file" {
      source      = "${var.key_path}/anthony-${var.a2_ip}.pem"
      destination = "C:\\Chef\\.chef\\anthony.pem"
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
      source      = "${var.key_path}/reesyorg-validator-${var.a2_ip}.pem"
      destination = "C:\\Chef\\.chef\\reesyorg.pem"
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

## Set wallpaper
resource "null_resource" "wallpaper_upload" {
  depends_on = ["null_resource.wait_for_mins"]
  provisioner "file" {
      source      = "${path.module}/scripts/wallpaper.png"
      destination = "C:\\Chef\\wallpaper.png"
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

resource "null_resource" "wallpaper_script_upload" {
  depends_on = ["null_resource.wallpaper_upload"]
  provisioner "file" {
      source      = "${path.module}/scripts/background.ps1"
      destination = "C:\\Chef\\background.ps1"
      connection {
          host = "${aws_instance.workstation.public_ip}"
          type     = "winrm"
          user     = "chef"
          password = "RL9@T40BTmXh"
          insecure = true
          timeout = "10m"
        }
  }
}
resource "null_resource" "wallpaper_run_script" {
  depends_on = ["null_resource.wallpaper_script_upload"]
  provisioner "remote-exec" {
    inline = [
      "powershell -ExecutionPolicy Unrestricted -File C:\\Chef\\background.ps1 -Schedule",
    ]
    connection {
          host = "${aws_instance.workstation.public_ip}"
          type     = "winrm"
          user     = "chef"
          password = "RL9@T40BTmXh"
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
