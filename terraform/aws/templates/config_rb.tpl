current_dir = File.dirname(__FILE__)
log_level :info
log_location STDOUT
node_name "${var_chef_user1}"
client_key "#{current_dir}/${var_chef_user1}.pem"
chef_server_url "https://${var_automate_hostname}/organizations/${var_chef_organization}"
cookbook_path ["#{current_dir}/../cookbooks"]