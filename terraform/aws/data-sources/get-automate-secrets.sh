#!/bin/bash
set -eu -o pipefail

export ssh_user
export ssh_key
export a2_ip
export chef_user
export chef_organization
export local_path

eval "$(jq -r '@sh "export ssh_user=\(.ssh_user) ssh_key=\(.ssh_key) a2_ip=\(.a2_ip) chef_user=\(.chef_user) chef_organization=\(.chef_organization) local_path=\(.local_path)"')"

scp -i ${ssh_key} ${ssh_user}@${a2_ip}:/home/${ssh_user}/automate-credentials.toml ${local_path}/automate-credentials-${a2_ip}.toml
scp -i ${ssh_key} ${ssh_user}@${a2_ip}:/home/${ssh_user}/${chef_user}.pem ${local_path}/${chef_user}-${a2_ip}.pem
scp -i ${ssh_key} ${ssh_user}@${a2_ip}:/home/${ssh_user}/${chef_organization}-validator.pem ${local_path}/${chef_organization}-validator-${a2_ip}.pem

a2_admin="$(cat ${local_path}/automate-credentials-${a2_ip}.toml | sed -n -e 's/^username = //p' | tr -d '"')"
a2_password="$(cat ${local_path}/automate-credentials-${a2_ip}.toml | sed -n -e 's/^password = //p' | tr -d '"')"
a2_token="$(cat ${local_path}/automate-credentials-${a2_ip}.toml | sed -n -e 's/^api-token = //p' | tr -d '"')"
a2_url="$(cat ${local_path}/automate-credentials-${a2_ip}.toml | sed -n -e 's/^url = //p' | tr -d '"')"

jq -n --arg a2_admin "$a2_admin" \
      --arg a2_password "$a2_password" \
      --arg a2_token "$a2_token" \
      --arg a2_url "$a2_url" \
      '{"a2_admin":$a2_admin,"a2_password":$a2_password,"a2_token":$a2_token,"a2_url":$a2_url}'
