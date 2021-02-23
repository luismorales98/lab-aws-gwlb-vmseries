# PS Regional Training 2021 AWS Labs


<img src="https://www.paloaltonetworks.com/content/dam/pan/en_US/images/logos/brand/primary-company-logo/Parent-logo.png" width=50% height=50%>

## Overview

This lab will involve deploying a solution for AWS using Palo Alto Networks VM-Series in the Gateway Load Balancer (GWLB) topology.

The lab assumes an existing Panorama that the VM-Series will bootstrap to. Panorama assumptions:
- Accessible with public IP on TCP 3978
- Prepped with Template Stacks and Device Groups
- vm-auth-key generated on Panorama

This guide is intended to be used with a specific QwikLabs scenario, and some steps are specific to Qwiklabs. This could be easily adapted for other environments.

## Step x: Initialize Lab

- Download `Lab Details` File from Qwiklabs interface for later reference
- Click Open Console and authenticate to AWS account with credentials displayed in Qwiklabbs
- Verify in correct region 

### Step x: Find SSH Key Pair Name

- EC2 Console -> Key pairs
- Copy and record the name of the Key Pair automatically generated, e.g. `qwikLABS-L17939-10286`
- In Qwiklabs console, download the ssh key for later use (PEM and PPK options available)

> &#8505; Any EC2 Instance must be associated with a SSH keypair, which is the default method of initial interactive login to EC2 instances. With successful bootstrapping, there should not be any need to connect to the VM-Series instances direclty with this key, but it is usually good to keep this key securely stored for any emergency backdoor access. For this lab, we will use the keypair automatically generated by Qwiklabs. The key will also be used for connecting to the test web server instances.


TODO: Use SSM for linux instances, then no need to handle keys

## Step x: Update IAM Policies


- Search for `IAM` in top searchbar (IAM is global)
- In IAM dashboard select Users -> awsstudent
- Expand `default_policy`, Edit Policy -> Visual Editor
- Find the Deny Action for `Cloud Shell` and click `Remove` on the right
- Review policy
- Save changes

---

<img src="https://user-images.githubusercontent.com/43679669/108776959-1882ba80-7531-11eb-8b8e-3247db81c3de.gif" width=50% height=50%>


> &#8505; Qwiklabs has an explicit Deny for CloudShell. However, we have permissions to remove this deny policy. Take a look at the other Deny statements while you are here.
---

## Step x: Launch CloudShell

- Search for `cloudshell` in top search bar
- Close out of the Intro Screen
- Allow a few moments for it to initialize

---
> &#8505; This lab will use cloudshell for access to AWS CLI and as a runtime environment to provision your lab resources in AWS using terraform. Cloudshell will have the same IAM role as your authenticated user and has some utilities (git, aws cli, etc) pre-installed. It is only available in limited regions currently.
>
> Anything saved in home directory `/home/cloudshell-user` will remain persistent if you close and relaunch CloudShell
---

## Step x: Search Available VM-Series Images (AMIs)

- In cloud console, enter:

```
aws ec2 describe-images --filters "Name=owner-alias,Values=aws-marketplace" --filters Name=name,Values=PA-VM-AWS-10* Name=product-code,Values=6njl1pau431dv1qxipg63mvah --region us-west-2
```

> &#10067; How many different BYOL AMIs are avilable for 10.x in this region?

- We see that `10.0.4` AMI is availble, which is what we are targeting for this deployment

> &#10067; What is the Marketplace AMI ID for 10.0.4 in this region?

> &#10067; What are some options if there is no AMI available for your targetd version?

- Try using query to control what data is returned

```
aws ec2 describe-images --filters "Name=owner-alias,Values=aws-marketplace" --filters Name=name,Values=PA-VM-AWS-10* Name=product-code,Values=6njl1pau431dv1qxipg63mvah --region us-west-2 --query 'Images[].[ImageId,Name]'
```

---

> &#8505;  This terraform deployment will look up the AMI ID to use for the deployment based on the variable `fw_version`. New AMIs are not always published for each minor release. Therefore, it is a good idea to verify what version AMI most closely matches your target version.

> &#8505; product-code is a global value that correlates with Palo Alto Networks marketplace offerings This is global and the same across all regions. There will be changes to this as vm-flex offerings come live.
>```
>   "byol"  = "6njl1pau431dv1qxipg63mvah"
>   "payg1" = "6kxdw3bbmdeda3o6i1ggqt4km"
>   "payg2" = "806j2of0qy5osgjjixq9gqc6g"
>```

> &#8505; The name tag of the image should be standard and can be used for the filter. For example `PA-VM-AWS-9.1*`, `PA-VM-AWS-9.1.3*`, `PA-VM-AWS-10*`. This is the same logic the terraform will use to lookup the AMI based on the `fw_version` variable.

---


## Step x: Download Terraform 

- Download Terraform in Cloudshell

```
mkdir /home/cloudshell-user/bin/ && wget https://releases.hashicorp.com/terraform/0.13.6/terraform_0.13.6_linux_amd64.zip && unzip terraform_0.13.6_linux_amd64.zip && rm terraform_0.13.6_linux_amd64.zip && mv terraform /home/cloudshell-user/bin/terraform
```

- Verify Terraform 0.13.6 is installed
```
terraform --version
```

> &#8505; Terraform projects often have version constraints in the code to protect against potentially breaking syntax changes when new version is released. For this project, the [version constraint](https://github.com/PaloAltoNetworks/ps-regional-2021-aws-labs/blob/main/terraform/vmseries/versions.tf) is:
> ```
> terraform {
>  required_version = ">=0.12.29, <0.14"
>}
>```
>
>Terraform is distributed as a single binary so isn't usually managed by OS package managers. It simply needs to be downloaded and put into a system `$PATH` location. For Cloudshell, we are using the `/home/cloud-shell-user/bin/` so it will be persistent if the sessions times out.


## Step x: Clone Deployment Git Repository 

- Clone the Repository with the terraform to deploy
  
```
$ git clone https://github.com/PaloAltoNetworks/ps-regional-2021-aws-labs.git && cd ps-regional-2021-aws-labs/terraform/vmseries
```

## Step x: Update Deployment Values in tfvars




For simplicity, only the variable values that need to be modified are separated into a separate tfvars file.


- Use vi to update values in `student.auto.tfvars`

```
vi student.auto.tfvars
```

- Update the specifics of your deployment
- Anything marked with `###` should be replaced with appropriate value
- Reference downloaded `lab-details.txt` for values

> &#8505; If you don't like vi, you can install nano editor:
> ```
> sudo yum install -y nano
> ```


<img src="https://user-images.githubusercontent.com/43679669/108796675-47138c00-7557-11eb-99b4-58141a3cf874.gif" width=50% height=50%>


```
firewalls = [
  {
    name    = "vmseries01"
    fw_tags = {}
    bootstrap_options = {
      mgmt-interface-swap = "enable"
      plugin-op-commands  = "aws-gwlb-inspect:enable"
      type                = "dhcp-client"
      hostname            = "lab###_vmseries01"
      panorama-server     = "###"
      panorama-server-2   = "###"
      tplname             = "TPL-STUDENT-STACK-###"
      dgname              = "DG-STUDENT-###"
      vm-auth-key         = "###"
      authcodes           = "###"
      #op-command-modes    = ""
    }
    interfaces = [
      { name = "vmseries01-data", index = "0" },
      { name = "vmseries01-mgmt", index = "1" },
    ]
  },
  {
    name    = "vmseries02"
    fw_tags = {}
    bootstrap_options = {
      mgmt-interface-swap = "enable"
      plugin-op-commands  = "aws-gwlb-inspect:enable"
      type                = "dhcp-client"
      hostname            = "lab###_vmseries02"
      panorama-server     = "###"
      panorama-server-2   = "###"
      tplname             = "###"
      dgname              = "###"
      vm-auth-key         = "###"
      authcodes           = "###"
      #op-command-modes    = ""
    }
    interfaces = [
      { name = "vmseries02-data", index = "0" },
      { name = "vmseries02-mgmt", index = "1" },
    ]
  }
]
```

> &#8505; This deployment is using a [newer feature for basic bootstrapping](https://docs.paloaltonetworks.com/plugins/vm-series-and-panorama-plugins-release-notes/vm-series-plugin/vm-series-plugin-20/vm-series-plugin-201/whats-new-in-vm-series-plugin-201.html) that does not require S3 buckets. Essentially, any paramaters normally specific in init-cfg can now be passed directly to the instance via user-data. Prerequisite is the image you are deploying has plugin 2.0.1+ installed

> &#8505; Notice the plugin-op-command to enable the GWLB inspection. There are additional bootstrap parameters planned for 10.0.5 to set GWLB sub-interface associations to endpoints.


> &#10067; What are some bootstrap options that won't be possible with this basic bootstrap method?

> &#8505; If you have time left after the rest of the lab activities, later steps will return to do some more digging into the terraform code.

- //TODO add notes about terraform general usage, handling sensitive values, etc


## Step x: Apply Terraform

- Make sure you are in the appropriate directory

```
cd /home/cloudshell-user/ps-regional-2021-aws-labs/terraform/vmseries
```
- Initialize Terraform

```
terraform init
```

- Apply Terraform

```
terraform apply
```

- When Prompted for confirmation, type `yes`


<img src="https://user-images.githubusercontent.com/43679669/108799781-36671400-755f-11eb-9724-d18c7ea147bb.gif" width=50% height=50%>


- It should take 5-10 minutes for terraform to finish deploying all resources.

- When complete, you will see a list of outputs. Copy these off locally so you can reference them in later steps. 
 
> &#8505; You can also come back to this directory in CloudShell later and run `terraform output` to view this information 



## Step x: Inspect deployed resources

All resources are now created in AWS, but it will be around 10 minutes until VM-Series are fully initialized and bootstrapped.

In the meantime, lets go look at what you built!


- EC2 Dashboard -> Instances -> Select `vmseries01` -> Actions -> Instance settings -> Edit user data

- Verify the values matches what was provided in your Lab Details

> &#10067; What are some tradeoffs of using user-data method for bootstrap vs S3 bucket?

> &#10067; What needs to happen if you have a typo or missed a value for bootstrap when you deployed?

---
### Step x.x Get VM-Series instance screenshot

- EC2 Dashboard -> Instances -> Select `vmseries01` -> Actions -> Monitor and troubleshoot -> Get instance screenshot

> &#8505; This can be useful to get a view of the console during launch. It is not interactive and must be manually refershed, but you can at least see some output related to bootstrap process or to troubleshoot if the VM-Series isn't booting properly or is in maintenance mode.

---

### Step x.x Check VM-Series instance details

- EC2 Dashboard -> Instances -> Select `vmseries01` -> Review info / tabs in bottom pane


> &#10067; What is the instance type? Which BYOL model(s) would this instance type be appropriate for?

> &#10067; How many interfaces are associated to the VM-Series? Which interface is the default ENI for the instance? Which interfaces have public IPs associated?

> &#10067; Check the security group associated with the "data" interface. What is allowed inbound? What is the logic of this SG?

> &#10067; What Instance Profile was the VM-Series launched with? What actions does it allow? What are some other use-cases where you need to allow additional IAM permissions for the instance profile?

---

### Step x.x Check cloudwatch bootstrap logs

- Search for `cloudwatch` in the top search bar
- Logs -> Log groups -> PaloAltoNetworksFirewalls
- Assuming enough time has passed since launch, verify that the bootstrap operations completed successfully.

> &#8505; It is normal for the VMs to lose connectivity to Panorama initially after first joining.

> &#10067; What is required to enable these logs during boot process?

---
### Step x.x Check networking

- Look at VPC & TGW route tables, endpoints, correlate to the topology diagram

//TODO - Add steps here

---

### Step x.x Check Load Balancers

- Health probes of GWLB
- Health probes of App VPC NLBs

//TODO - Add steps here

---

## Step x: Verify Bootstrap in Panorama

//TODO - Add Steps

- Inspect pre-prepped networking config and policies

## Step x: Update VPC networking for GWLB

//TODO - Currently TF deploying all VPC / endpoint routing. Want to remove and have add manual steps


## Step x: Access web servers

- ssh from local machine to the NLB associate with app1 and app2 apps
  -  hostname will be the FQDN of the NLBs from the terraform output
  - username is `ec2-user`
  - ssh key was downloaded from Qwiklabs console

```
ssh -i ~/.ssh/qwikLABS-L17939-10296.pem ec2-user@ps-lab-app1-nlb-d42f371991908c49.elb.us-west-2.amazonaws.com
```

> &#8505; We now have secured inbound connectivity but instances do not yet have a path outbound / inbound

//TODO - Add Steps

## Step x.x: Update TGW Route Tables

- VPC Dashboard -> Tranist Gateway Route Tables -> Select `ps-lab-from-spoke-vpcs`
  -  Check `Associations` tab and verify the two spoke App VPCs are associated
  -  Check Routes tab and notice there are no existing routes
  -  Create Static Route (Default to security VPC)
     - CIDR: 0.0.0.0/0
     - Attachment: Security VPC (Name Tag = ps-lab-security-vpc)

- VPC Dashboard -> Tranist Gateway Route Tables -> Select `ps-lab-from-security-vpc`
  -  Check `Associations` tab and verify the security VPC is associated
  -  Check `Routes` tab and notice there are no existing routes
  -  Select Propagations Tab -> Create Propagation
  -  Select attachement with Name Tag `ps-lab-app1-vpc`
  -  Repeat for attachement with Name Tag `ps-lab-app2-vpc`
  -  Return to `Routes` tab and verify the table now has routes to reach the App VPCs 

> &#8505; For GWLB model, the OB/EW TGW routing is mostly the same as previous TGW models. Spoke TGW RT directs all traffic to Security VPC. Security TGW RT has routes to reach all spoke VPCs for return traffic.
>
>For OB/EW, the GWLB doesn't come into play until traffic comes into the Security VPC

## Step x: Access VM-Series management

//TODO - Add Steps


## Step x: Test Traffic flows

//TODO - Add Steps
E/W, outbound, inbound

Inspect FW logs


## Step x: Configure GWLB sub-interface associations

//TODO - Add Steps

## Step x: Test Traffic flows

//TODO - Add Steps
E/W, outbound, inbound
Inspect logs

## Step 50: Finished

Congratulations!

You have now successfully ….


Manual Last Updated: 2021-02-16
Lab Last Tested: -

