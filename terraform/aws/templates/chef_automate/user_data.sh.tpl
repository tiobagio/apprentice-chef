# Download profiles for Audit cookbook

download_compliance_profiles() {
    for PROFILE in \
        linux-baseline \
        cis-centos7-level1 \
        cis-ubuntu16.04lts-level1-server \
        windows-baseline \
        cis-windows2012r2-level1-memberserver \
        cis-windows2016-level1-memberserver \
        cis-windows2016rtm-release1607-level1-memberserver \
        cis-rhel7-level1-server \
        cis-sles11-level1 
    do 
        echo "$PROFILE" 
        VERSION=`curl -s -k -H "api-token: $TOKEN" https://${var_automate_hostname}/api/v0/compliance/profiles/search  -d "{\"name\":\"$PROFILE\"}" | /snap/bin/jq -r .profiles[0].version`

        echo "Version:  $VERSION" 
        curl -s -k -H "api-token: $TOKEN" -H "Content-Type: application/json" 'https://${var_automate_hostname}/api/v0/compliance/profiles?owner=admin' \
            -d  "{\"name\":\"$PROFILE\",\"version\":\"$VERSION\"}"
        echo
        echo
    done
}


isrunning () {
  if sudo $1 status >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}


exists () {
  if sudo $1 version >/dev/null 2>&1
  then
    return 0
  else
    return 1
  fi
}


install_a2() { 
    sudo snap install jq
    sudo hostnamectl set-hostname ${var_automate_hostname} 
    if isrunning chef-automate; then
       sudo chef-automate stop
    fi

    sudo sysctl -w vm.max_map_count=262144 
    sudo sysctl -w vm.dirty_expire_centisecs=20000
    sudo mkdir -p /etc/chef-automate 

    curl https://packages.chef.io/files/${var_channel}/latest/chef-automate-cli/chef-automate_linux_amd64.zip |gunzip - > chef-automate && chmod +x chef-automate
    sudo ./chef-automate init-config --file /tmp/config.toml $(if ${var_automate_custom_ssl}; then echo '--certificate /tmp/ssl_cert --private-key /tmp/ssl_key'; fi)
    sudo sed -i 's/fqdn = \".*\"/fqdn = \"${var_automate_hostname}\"/g' /tmp/config.toml
    sudo sed -i 's/channel = \".*\"/channel = \"${var_channel}\"/g' /tmp/config.toml
    sudo sed -i 's/license = \".*\"/license = \"${var_automate_license}\"/g' /tmp/config.toml
#   "sudo rm -f /tmp/ssl_cert /tmp/ssl_key",

    sudo mv /tmp/config.toml /etc/chef-automate/config.toml 
    sudo ./chef-automate deploy /etc/chef-automate/config.toml --product automate --product chef-server --product builder --accept-terms-and-mlsa
#   sudo ./chef-automate applications enable
#   sudo ./chef-automate config patch /tmp/automate-eas-config.toml

}


update_a2_fqdn() { 
    echo "Changing Automate fqdn to ${var_automate_hostname}...."

    sudo ./chef-automate config show > /tmp/update_config.toml
    sudo sed -i 's/fqdn = \".*\"/fqdn = \"${var_automate_hostname}\"/g' /tmp/update_config.toml
    sudo ./chef-automate config patch /tmp/update_config.toml 
    sudo hostnamectl set-hostname ${var_automate_hostname} 
}


create_infra_users() { 
    sudo chef-server-ctl user-create ${var_chef_user1} chef user ${var_chef_user1}@chef.io '1234chefabcd' --filename $HOME/${var_chef_user1}.pem
    sudo chef-server-ctl org-create ${var_chef_organization} 'automate' --association_user ${var_chef_user1}  --filename $HOME/${var_chef_organization}-validator.pem
}


create_a2_users() {
    echo "xxxxx Add Automate Users xxxxx"
    export TOKEN=`sudo chef-automate admin-token`
    echo $TOKEN
    PASSWORD="${var_a2_password}"
    for i in {1..10}
    do
        USERNAME="${var_a2_user}-$i"
        echo "creating user $USERNAME"
	curl -k -H "api-token: $TOKEN" -H "Content-Type: application/json" https://${var_automate_hostname}/api/v0/auth/users?pretty \
        --data "{\"name\":\"$USERNAME\", \"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}"
    done
}

output_information() {
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Client PEM xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" 
    sudo cat $HOME/${var_chef_user1}.pem
    echo
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx Validator PEM xxxxxxxxxxxxxxxxxxxxxxxxxxxx" 
    sudo cat $HOME/${var_chef_organization}-validator.pem
 
    sudo chown ubuntu:ubuntu $HOME/automate-credentials.toml 
    sudo echo -e \"api-token =\" $TOKEN >> $HOME/automate-credentials.toml
    sudo cat $HOME/automate-credentials.toml
}

install_chef_workstation() {
    echo "xxxxx Install Chef Workstation xxxxx"
    sudo wget https://packages.chef.io/files/stable/chef-workstation/0.17.5/ubuntu/18.04/chef-workstation_0.17.5-1_amd64.deb
    sudo dpkg -i chef-workstation_0.17.5-1_amd64.deb
}

config_workstation() {
    chef generate repo chef-repo --chef-license accept
    mkdir -p /home/ubuntu/chef-repo/.chef
    cp /home/ubuntu/${var_chef_user1}.pem /home/ubuntu/chef-repo/.chef/${var_chef_user1}.pem

    echo 'log_location     STDOUT' >> /home/ubuntu/chef-repo/.chef/config.rb
    echo -e "chef_server_url 'https://${var_automate_hostname}/organizations/${var_chef_organization}'" >> /home/ubuntu/chef-repo/.chef/config.rb
    echo -e "validation_client_name '${var_chef_user1}'" >> /home/ubuntu/chef-repo/.chef/config.rb
    echo -e "validation_key '/home/ubuntu/chef-repo/.chef/${var_chef_user1}.pem'" >> /home/ubuntu/chef-repo/.chef/config.rb
    echo -e "node_name '${var_chef_user1}'" >> /home/ubuntu/chef-repo/.chef/config.rb
    echo -e "ssl_verify_mode :verify_none" >> /home/ubuntu/chef-repo/.chef/config.rb
}

install_cookbooks(){
    cd /home/ubuntu/chef-repo
    knife ssl fetch
    
    cd /home/ubuntu/chef-repo/cookbooks
    git clone https://github.com/anthonygrees/audit_agr
    cd /home/ubuntu/chef-repo/cookbooks/audit_agr
    berks install
    berks upload

    cd /home/ubuntu/chef-repo/cookbooks
    git clone https://github.com/anthonygrees/chef-client
    cd /home/ubuntu/chef-repo/cookbooks/chef-client
    berks install
    berks upload
}

if test "x${var_upgrade_flag}" == "xtrue"; then
    echo "Installing Chef Automate ..."
    install_a2
    sleep 60
    create_a2_users
    create_infra_users

    # use TOKEN
    download_compliance_profiles
    output_information

    install_chef_workstation
    config_workstation
    install_cookbooks
else
    update_a2_fqdn
fi
