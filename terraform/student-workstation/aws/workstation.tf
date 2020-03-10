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

## Copy the User and Validator PEM files for knife to work on the Student Workstation
  provisioner "file" {
      source      = "${path.module}/files/user_pem"
      destination = "C:/Chef/.chef/anthony.pem"
  }
  provisioner "file" {
    source      = "${path.module}/files/validator_pem"
    destination = "C:/Chef/.chef/reesyorg.pem"
  }

  tags {
    Name          = "${var.tag_contact}-${var.tag_customer}-habworkshop-${count.index}"
    X-Dept        = "${var.tag_dept}"
    X-Customer    = "${var.tag_customer}"
    X-Project     = "${var.tag_project}"
    X-Application = "${var.tag_application}"
    X-Contact     = "${var.tag_contact}"
    X-TTL         = "${var.tag_ttl}"
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "PowerShell.exe -Command \"cmder\"",
  #   ]
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "PowerShell.exe -Command \"start-process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe -ArgumentList 'www.quora.com''\"",
  #   ]


  }