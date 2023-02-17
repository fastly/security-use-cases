# What's in the Gold Standard Starter?

* A Request Rule that adds a Custom Signal for requests that match for System Attacks AND frequent attack sources
* A List and a Rule for a default Geoblocking policy
* A Request Rule that consolidates System Attacks under one Signal 
* An Alert that lowers thresholds for Any System Attack Signal
* A custom rule to tag a base set of Anomaly signals


# Step 0
[Install terraform](https://developer.hashicorp.com/terraform/downloads)

# Step 1
Run `terraform init` within the gold-standard-starter directory

# Step 2
Run `terraform apply` within the gold-standard-starter directory
    - You will be prompted to enter details. Enter the appropriate information.
    - You must respond with "yes" for the terraform configuration to actually apply

# Need to restart?
Just run `terraform destroy` to delete any resources created by terraform after running `terraform apply`
