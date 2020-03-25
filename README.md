# Apprentice Chef - Create Chef Training Environment

### About
This repo creates a Chef Training Environment to teach Chef Essentials, Introduction to Inspec and Habitat Jumpstart.  It creates the following:
- Chef Environment
    - Chef Automate
      - Loads InSpec Profiles
      - Creates 10 local users for the students
    - Chef Infra Server
      - Creates user pem and org validator
    - Habitat OnPrem Builder

- Student Workstation
  - Windows 2016 Student Workstation(s)
    - Installs VS Code, Git, Cmder, Chrome, Chef Workstation
    - Creates a working directory in `C:\Chef`
    - Configures Test-Kitchen
    - Configures Knife to communicate with the Chef Server

#### Other Resources
This environment is made to work with the following training repo - https://github.com/anthonygrees/compliance-workshop

Policyfiles training - https://github.com/anthonygrees/policyfiles_training


### Step 1 - Get Started
First you need the code !
```bash
git clone https://github.com/anthonygrees/apprentice-chef

cd apprentice-chef
```

### Step 2 - Chef Training Environment

Creates and configures Chef Automate, Chef Infra Server and Habitat On Prem Builder.

On Chef Server a User is created called `anthony` and the PEM file.  An ORG is created called `ressyorg` and a validator PEM file.

On Chef Automate, it downloads the following InSpec profiles ready to be used:
- linux-baseline
- cis-centos7-level1
- cis-ubuntu16.04lts-level1-server
- windows-baseline
- cis-windows2012r2-level1-memberserver
- cis-windows2016-level1-memberserver
- cis-rhel7-level1-server
- cis-sles11-level1

The Local Users for students created at `Workstation-1` thru `Workstation-10` and the credentials are as follows:
- User: `workstation-1`
- Password: `workstation!`

#### The Client and Validator PEM files
When the Chef Infra Server is created, the User and ORG (validator) pem files are output.  You can also find copies on the server at:
- User pem file required by Knife - `/home/ubuntu/anthony.pem`
- Validator pem file required for bootstrapping nodes - `/home/ubuntu/reesyorg-validator.pem`

The PEM files are also `SCP`d to your Laptop.  You can find them at `/Users/<username>/` and their names are:
- `<username>-<automate-ip>.pem`
- `<org>-validator-<automate-ip>.pem`

### Step 3- Student Workstations

Creates and configures the Student Workstations on a Windows 2016 server.  It installs the following:
- Chef Workstation
- Cmder (Windows Terminal)
- Git
- Google Chrome
- VS Code

It configures `knife` and creates a folder in `C:\Chef` that has all the PEM files in the `C:\Chef\.chef` for the Chef Workstation to talk to Chef Server and Automate.

#### Windows Credentials
User - `chef`
Password - `RL9@T40BTmXh`

#### Set the PEM files
The two PEM files created by the Chef Server when you ran the `terraform` above have been stored on your Laptop at `/Users/<username>/` and their names are:
- `<username>-<automate-ip>.pem`
- `<org>-validator-<automate-ip>.pem`

These will then be copied to the Student Workstation so that `knife` can connect to the Chef Server.

### Create the Chef Training Environment
```bash
cd terraform/aws/
```

Execute the terraform. First run the initialise to ensure the plugins you need are installed:

```bash
terraform init
```
Before you run Terraform to create your infrastructure, it's a good idea to see what resources it would create. It also helps you verify that Terraform can connect to your AWS account.

```bash
terraform plan
```

and then apply to create the infrastructure.

```bash
terraform apply -auto-approve
```

### What does it create ?

It will create the following servers
- Ubuntu VM with Chef Automate, Chef Infra Server and Habitat On Prem Builder
- Windows Student workstation (1 for each student)

Once successfully created, you will get an output like this:
![TerraformOutput](/images/automate_output.png)

### Debuging

Set the log level
```bash
export TF_LOG=TRACE
```
Push the ```terraform``` output to a file
```bash
export TF_LOG_PATH=./terraform.log
```

Rerun for one state only
```bash
terraform state list
```

Your output will look like this
```bash
aws_ami.windows_workstation
aws_instance.workstation
aws_internet_gateway.habworkshop-gateway
aws_route.habworkshop-internet-access
aws_security_group.habworkshop
aws_security_group_rule.ingress_rdp_all
aws_security_group_rule.ingress_winrm_all
aws_security_group_rule.windows_egress_allow_0-65535_all
aws_subnet.habworkshop-subnet
aws_vpc.habworkshop-vpc
null_resource.key_user
random_id.instance_id
```

Remove the state
```bash
terraform state rm null_resource.key_user
```
Re apply


## License and Author

* Author:: Anthony Rees <anthony@chef.io>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.