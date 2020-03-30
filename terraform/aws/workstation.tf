resource "aws_instance" "workstation" {
    depends_on = [aws_instance.chef_automate]

  connection {
    type     = "winrm"
    user     = "hab"
    password = "ch3fh@b1!"
  }

  count                       = var.counter
  ami                         = data.aws_ami.windows_workstation.id
  instance_type               = "t3.large"
  key_name                    = var.aws_key_pair_name
  subnet_id                   = aws_subnet.habmgmt-subnet-a.id
  vpc_security_group_ids      = [aws_security_group.habworkshop.id]
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
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    netsh advfirewall firewall add rule name=”WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
    netsh advfirewall firewall add rule name=”WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
    netsh advfirewall firewall add rule name=”RDP 3389" protocol=TCP dir=in localport=3389 action=allow
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
    command = "sleep 320"
  }
}

resource "null_resource" "chef" {
  depends_on = [null_resource.wait_for_mins]
  count = var.counter
  provisioner "remote-exec" {
    inline = [
      "cd C:\\",
      "PowerShell.exe -Command \"Set-MpPreference -DisableRealtimeMonitoring $true\"",
      "PowerShell.exe -Command \". { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -channel current -project chef-workstation\"",
    ]
      connection {
        host = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = "chef"
        password = "RL9@T40BTmXh"
        insecure = true
        timeout = "15m"
      }
  }
}

resource "null_resource" "chef1" {
  depends_on = [null_resource.chef]
  count = var.counter
  provisioner "remote-exec" {
    inline = [
      "choco install googlechrome -y",
      "choco install vscode -y",
      "choco install cmder -y",
      "choco install git -y",
      "choco install notepad++ -y",
      "choco upgrade googlechrome -y",
      "choco install setdefaultbrowser -y",
      "SetDefaultBrowser.exe HKLM \"Google Chrome\"",
      "cd C:\\",
      "chef generate repo chef-repo --chef-license accept",
      "git config --global user.email \"me@chef.io\"",
      "git config --global user.name \"Chef\"",
      "md C:\\chef-repo\\.chef",
      "PowerShell.exe -Command \"Set-MpPreference -DisableRealtimeMonitoring $false\"",
    ]
      connection {
        host = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = "chef"
        password = "RL9@T40BTmXh"
        insecure = true
        timeout = "15m"
      }
  }
}

resource "null_resource" "key_user" {
  depends_on = [null_resource.chef1]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_user1}-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\chef-repo\\.chef\\${var.chef_user1}.pem"
      connection {
        host = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = "hab"
        password = "ch3fh@b1!"
        insecure = true
        timeout = "10m"
      }
  }

}

resource "null_resource" "key_validator" {
  depends_on = [null_resource.chef1]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/${var.chef_organization}-validator-${aws_instance.chef_automate.public_ip}.pem"
      destination = "C:\\chef-repo\\.chef\\${var.chef_organization}.pem"
      connection {
          host = aws_instance.workstation[count.index].public_ip
          type     = "winrm"
          user     = "hab"
          password = "ch3fh@b1!"
          insecure = true
          timeout = "10m"
        }
  }
}

resource "null_resource" "key_kitchen" {
  depends_on = [null_resource.chef1]
  count = var.counter
  provisioner "file" {
      source      = "${var.key_path}/src/cookbooks/id_rsa"
      destination = "C:\\Users\\Chef\\.ssh\\id_rsa"
      connection {
          host = aws_instance.workstation[count.index].public_ip
          type     = "winrm"
          user     = "hab"
          password = "ch3fh@b1!"
          insecure = true
          timeout = "10m"
        }
  }
}

resource "null_resource" "copy_config_rb" {
  depends_on = [null_resource.key_kitchen]
  count = var.counter
  provisioner "file" {
    content      = templatefile("${path.module}/templates/config_rb.tpl", { var_chef_user1 = var.chef_user1, var_automate_hostname = var.automate_hostname, var_chef_organization = var.chef_organization })
    destination = "C:\\chef-repo\\.chef\\config.rb"
    connection {
        host = aws_instance.workstation[count.index].public_ip
        type     = "winrm"
        user     = "chef"
        password = "RL9@T40BTmXh"
        insecure = true
        timeout = "10m"
    }
  }
}

resource "null_resource" "open_a2" {
  depends_on = [null_resource.copy_config_rb]
  count = var.counter
  provisioner "file" {
    content      = templatefile("${path.module}/templates/open_a2.cmd.tpl", { var_automate_hostname = var.automate_hostname })
    destination = "C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\open_a2.cmd"
      connection {
          host = aws_instance.workstation[count.index].public_ip
          type     = "winrm"
          user     = "chef"
          password = "RL9@T40BTmXh"
          insecure = true
          timeout = "10m"
        }
  }
}