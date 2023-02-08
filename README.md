# security-use-cases
As much fun as clicking and typing are, how about we give our weary hands a break and let Terraform do the work.

# What's all here?
Much inspiration from [10 Pro Tips for Getting the Most out of your Next-Gen WAF](https://www.fastly.com/blog/10-pro-tips-for-getting-the-most-out-of-your-next-gen-waf)

# What's been implemented so far?
## In Gold Standard Starter
* Tune Attack Thresholds
* Block Attacks from Malicious IPs
* Block Requests from non-revenue generating countries

## In Use Cases Plus
* Block Requests from Known Bad User Agents
* Block Requests with Invalid Host Header
* Rate Limiting Enumeration Attempts


# step 0
Install terraform

# Step 1
Run `terraform init`
Run `terraform apply`
    - You will be prompted to enter details. Enter the appropriate information.
    - You must respond with "yes" for the terraform configuration to actually apply

# Need to restart?
Just run `terraform destroy` to delete any resources created by terraform

# Backlog
Feel free to submit something to our backlog 
[COOKBOOKs Backlog](https://fastly.atlassian.net/jira/software/c/projects/COOK/boards/1208/backlog?issueLimit=100)
