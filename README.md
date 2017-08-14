# Prometheus Template

If you're reading this, it means you have some interest in collecting all sorts of metrics about your services and building amazing dashboards on top of them.

Unfortunately thou you're running your stuff in AWS and there is no *Out of the box* solution for spinning your monitoring system and keeping it up-to-date with ease.
  
Well, you're in the right spot. This project makes the whole thing quick and simple.

What is prometheus [Prometheus website](https://prometheus.io/)

And grafana? [Grafana website](https://grafana.com/)
 
## Prometheus template

The `prometheus-template` project is born from the hashes of the `aws_prometheus_ecs_template` and allows developers to spin a Prometheus + Grafana stack in just a few clicks.

The stack will create an EC2 instance and run via docker the following services:

* Prometheus Server
* Prometheus Alertmanager
* Prometheus Push Gateway
* Grafana

It will also create DNS resources, a large and fast disk where to store *all-the-data* and scripts to keep services and configuration up-to-date. More on the last topic below.
 
### Convention over configuration

The CFN stack and its scripts are parameterised, **BUT** location of files within the script are not. This is the keep scripts stupid and easily maintainable. The biggest example is the `config`
folder and its structure (sub-folders).

## How to create the stack

First of all you have to crete a clone of this this repo (see next paragraph).

The rationale behind is to keep this repo as the *master repo* to which everyone can contribute. The *master repo* will be kept in a clean healthy state with the use of tags or versions.

Each team can rebase releases into their projects. 

The important bit is that this repo will be team agnostic, so your configuration should be kept in your own fork. 

So, have you cloned this repo yet?

### Fork the repo

Since forking a project is not allowed within the same organization, create an empty project with a meaningful name, something that has the name of your team inside maybe: `team_X-prometheus` or `team_X-operations`

Clone the new empty project and then fetch the code from the *master repo* by following the instructions below:
 
```
git remote add upstream git@github.com:nemo83/aws_prometheus_template.git
git fetch upstream
git merge upstream/master
git push
```
 
There you go, your project is initialised and the template is now pushed to your github.

In order to fetch updates you simply need to iterate thru the scribe above, but skipping the `remote  add` part:

```
git fetch upstream
git merge upstream/master
git push
```

### Stack's parameters

This paragraph is definitely the most boring part of this guide. But hey no pain no gain!!

* DnsName: this is an easy one, DNS name for your service. AWS > Route53 > Hosted Zones > Domain Name. Pick one and prepend something meaningful: team_X-operations.\[DOMAIN_NAME\]. E.g. `my-great-team-operations.my-company.com`
* HostedZoneName: it's like the name above, but w/o the initial part, like `.my-company.com` 
* KeyName: this is the name of the key used to ssh onto the box, create a new one, or: AWS > EC2 > Instances > Find your favourite instance > Key pair name. That should work.
* InstanceType: You know what this is, right?
* DiskSize: Optional. Size of the Data Volume. At the moment of writing it's 64GB.
* AmiId: Optional. AMI to use on the EC2 instance.
* AvailabilityZones: Check in AWS > EC2 > Instances > Instance > Availability Zone, and find the two regions used in your account. 
* TargetSubnets: The **private** subnets associated to the Availability Zones above. AWS > VPC > Subnets > Subnet ID. Even if we only create stuff in one subnet, your ELB needs two. 
so take note of the subnet-id for both the regions at the previous step. Eg: "subnet-123456,subnet-78901"
* VpcId: AWS > VPC > Your VPCs > VPC ID. There should be only one. If more you may be on someone else account. (Just messing)
* BastionCIDR: it's the ip address of your bastion, the host where you can ssh from.  
* GitHubEncryptedToken: This has to be a KMS encrypted github token for the forked repo. Alright, read below.
* GitHubProject: the fork of the current project, in the format `organization/repo.git`. E.g. git@github.com:nemo83/aws_prometheus_template.git

### Creating the stack

We're almost there.

In the root of the project there is one last file to modify before being able to create the stack and it's `aws.mk`

Edit it and set the two following params:

```
AWS_PROFILE=aws-something
STACK_NAME=team_name-prometheus
```

The `AWS_PROFILE` is the one you use to deploy stuff to AWS, and the `STACK_NAME` is the name you want to give to the ... stack! Set it to something useful, like `team_X-prometheus.`

Once you've set all the Cloudformation params in `aws/cfn-parameters.json` and updated the `aws.mk` you can now proceed with the stack creation.

You most likely rely on the `awstoken` script to obtain temporary tokens, run in now and retrieve token for the same `AWS_PROFILE` you've set earlier on.

Then, before the token expire, run:

`make create-stack`

and cross your fingers.

If everything goes fine the stack along all its resources should be created.

You can then access the following urls:

* http://\[ec2.instance.name.mycompany.com\] -> Grafana
* http://\[ec2.instance.name.mycompany.com\] -> Prometheus
* http://\[ec2.instance.name.mycompany.com\] -> Alertmanager

Prometheus has no credentials, while the initial Grafana one are **admin/admin**

### Grafana config

In order to hook-up the Prometheus and Grafana instance you have to configure the Prometheus Datasource in Grafana.
 
Check the documentation to know more about what other Datasources Grafana support.

 Log on Grafana > Datasource > Add data source, and in the panel set:
 
 * Name: Prometheus
 * Type: Prometheus
 * URL: http://prometheus:9090/prometheus
 * Access: proxy (don't ask me why...)
 
 Hit `Save & Test`, a green bar should confirm all is working. You may even click on dashboard and enable the default 
 Prometheus Dashboard in Grafana.

### Updating the Stack

In order to modify the stack I would strongly recommend to update the configuration file or the aws stack definition in the
`aws` folder.

Once you're happy with that, you can easily push the changes to aws issuing the command:
```bash
cd aws
make update-stack
```

### Automagically update configuration

> Fine it all looks good, I've created the Prometheus example Dashboard, now I wanna monitor my own $%&*, how do I go about that?

Simple, in your repo there's a config folder with two subfolders:

* prometheus
* alertmanager

You have to enhance them so to start monitoring you ec2 instances.

Branch off master, make some changes, issue a PR and let your teammates to review changes. Prometheus will refuse broken configs and 
run on the last working configuration. PRs are also a good way of sharing knowledge.

> Ok, I've merged and nothing happens.
 
I'm happy you got here. You must really like Prometheus and Grafana. 

There is the last one little bit of work you have to do (I know I know, I promise is the very last bit!), but I inform you, you may need
someone with super powers.

So what is missing is a way of letting github informing your superclever stack that a commit happened (and the config is updated.)

In order to do so you need a *AWS User* able to send *stuff* to a *SQS Queue*. No worries, queue and listener have already been created for you. 
You'll have to create a user for yourself and configure your repo with the credentials.

Steps: 

* Create a AWS User with the only SQS SendMessage permission (you can find the resource name in the AWS > Cloudformation > Stack name and should
look like `gituhub-notifications-${AWS::StackName}`)
* Gihub > Project Name > Integration Services > Add Service > SQS, and fill the blanks with the params of your user

### Github token and encryption

In order to update both Prometheus Server and Alertmanager configurations, this stack requires a github token to clone/update the configuration yml files.

Since with a github tokens can be **very** dangerous and we don't want to commit them into the version control, you can encrypt it with KMS and let the stack do decrypt it when the stack is created (or updated).

A way of encrypt the token is

* Create a new KMS key if you don't have one already
* Create the github token with wich you plan to access the fork to this repo 
* Paste the token in a file called `github-token` 
* Run `aws kms encrypt --key-id [the_key_id] --plaintext fileb://github-token --output text --query CiphertextBlob > ./encrypted-github-token`
* Paste the content of the `./encrypted-github-token` into the `GitHubEncryptedToken` field

### Pro tips

> with great power comes great responsibility 

Prometheus is powerful... but you can mess it pretty badly and pretty quickly. Read this: [Prometheus Naming](https://prometheus.io/docs/practices/naming/). Specially the **CAUTION** at the bottom of the page. 
Don't come back to me crying, I'll **just** reply *I told you*.

### Fetch updates

How to fetch updates:

`git fetch upstream`

`git merge upstream/master`


 