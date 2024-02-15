# Instructions to run the project (tf-gcp-infra)

## API's enabled:

Compute Engine API
Cloud OS Login API

## setting up gcloud on your local machine

```
gcloud auth application-default login
```

## setting up terraform

```
<!-- initialize terraform -->
terrafrom init
<!-- validate terraform configs-->
terrafrom validate
<!-- see what changes are going to me made to the infra. -->
terrafrom plan -var-file=<your-var-file-name>
<!-- apply the changes  -->
terraform appy --var-file=<your-var-file-name>
```

### Example var file

region = "us-east1"
project_id = <your_project_id>

vpcs = [
{
vpc_name = <vpc-name>
vpc_auto_create_subnetworks = <true_or_false>
vpc_routing_mode = "REGIONAL"
vpc_delete_default_routes_on_create = <true_or_false>
subnets = [
{
name = <subnet_1>
ip_cidr_range = "10.0.1.0/24"
},
{
name = <subnet_2>
ip_cidr_range = "10.0.2.0/24"
},
]
routes = [
{
name = <name_your_route>
dest_range = "0.0.0.0/0"
next_hop_gateway = "default-internet-gateway"
}
]
}
]

#### Author: Varun Jayakumar
