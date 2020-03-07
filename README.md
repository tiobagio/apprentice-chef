# Apprentice Chef - Create Chef Training Environment

### About
This repo creates a Chef Training Environment to teach Chef Essentials, Introduction to Inspec and Habitat Jumpstart.  It creates the following:
- Chef-Env
    - Chef Automate
    - Chef Infra Server
    - Habitat OnPrem Builder

- Student-Workstation
  - Windows 2016 Student Workstation(s)

### Get Started
First you need the code !
```bash
git clone https://github.com/anthonygrees/apprentice-chef

cd apprentice-chef
```

### Chef Training Environment

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

#### Create the Chef Training Environment
```bash
cd terraform/aws/chef-env
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

Once successfully created, you will get an output like this:
![TerraformOutput](/images/automate_output.png)

### Capture the Client and Validator PEM files
When the Chef Infra Server is created, the User and ORG (validator) pem files are output.  You can also find copies on the server at:
- User pem file required by Knife - `/home/ubuntu/anthony.pem`
- Validator pem file required for bootstrapping nodes - `/home/ubuntu/reesyorg-validator.pem`

The PEM files are also output in the `terraform` stdout in the CLI.

### Student Workstations

Creates and configures the Student Workstations on a Windows 2016 server.  It installs the following:
- Chef Workstation
- Cmder (Windows Terminal)
- Git
- Google Chrome
- VS Code

It configures `knife` and creates a folder in `C:\Chef` that has all the PEM files in the `C:\Chef\.chef` for the Chef Workstation to talk to Chef Server and Automate.

### Windows Credentials
User - `chef`
Password - `RL9@T40BTmXh`

### Set the PEM files
You need to take the two PEM files created by the Chef Server when you ran the `terraform` above and copy them into:
- `/apprentice-chef/student-workstation/files/user.pem.file`
- `/apprentice-chef/student-workstation/files/validator.pem.file`

These will then be copied to the Student Workstation so that `knife` can connect to the 

#### Create the Chef Training Environment
```bash
cd terraform/aws/student-workstation
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

Once successfully created, you will get an output like this:
![TerraformOutput](/images/student_output.png)



## License and Author

* Author:: Anthony Rees <anthony@chef.io>

* Awesome Contributions From:: 
*** Nigel Wright - https://github.com/nwright-nz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

