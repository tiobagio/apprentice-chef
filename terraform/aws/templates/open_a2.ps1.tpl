cd C:\
Set-MpPreference -DisableRealtimeMonitoring $true
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -channel current -project chef-workstation

# already installed
#
#choco install googlechrome -y
#choco install vscode -y
#choco install cmder -y
#choco install git -y

choco install setdefaultbrowser -y --no-progress
choco upgrade googlechrome -y --no-progress

Set-MpPreference -DisableRealtimeMonitoring $false

chef generate repo chef-repo --chef-license accept
git config --global user.email "me@chef.io"
git config --global user.name "Chef"
md C:\chef-repo\.chef

New-Item -Path C:\chef-repo\.chef\ -Name "config.rb" -ItemType "file" -Value ""
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'current_dir = File.dirname(__FILE__)'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'log_level                :info'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'log_location             STDOUT'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'node_name                "${var_chef_user1}"'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'client_key               "#{current_dir}/${var_chef_user1}.pem"'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'chef_server_url          "https://${var_automate_hostname}/organizations/${var_chef_organization}"'
Add-Content -Path C:\chef-repo\.chef\config.rb -Value 'cookbook_path            ["#{current_dir}/../cookbooks"]'


SetDefaultBrowser.exe HKLM "Google Chrome"
Start-Process https://${var_automate_hostname}
