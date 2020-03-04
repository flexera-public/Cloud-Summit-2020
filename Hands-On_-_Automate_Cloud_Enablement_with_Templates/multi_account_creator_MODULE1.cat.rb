name "Multi Cloud Account Creator - Module 1 - <USER>"
rs_ca_ver 20161221
short_description "Creates a Cloud Tenant in AWS, Azure, or GCP."
import "sys_log"

##############
# Parameters #
##############

# What should we call the account in the provider/CMP?
parameter "param_account_name" do
  label "Account Name"
  type "string"
  category "Cloud"
end

# Who is the account owner? MUST BE UNIQUE
parameter "param_email" do
  label "Owner Email Address"
  type "string"
  category "Cloud"
end

# What Business Unit?
parameter "param_ou_lob_parent" do
  label "Business Unit"
  type "string"
  category "Cloud"
end

# What Cloud?
parameter "param_provider" do
  label "Cloud Provider"
  type "string"
  category "Cloud"
end

############
# Mappings #
############

# Map clouds to CMP coud account region is
mapping "map_cloud_accounts" do {
  "AWS" => {
    "clouds" => ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "12", "13", "14"]
  },
  "Azure" => {
    "clouds" => ["3518","3519","3520","3521","3522","3523","3524","3525","3526","3527","3528","3529","3530","3531","3532","3537","3538","3546","3547","3567","3568","3569","3570","3571","3749","3756"]
  },
  "GCP" => {
    "clouds" => ["2175"]
  }
}
end

# Map regions to CMP Cloud Hrefs
mapping "map_cloud_regions" do {
  "AWS" => {
    "us-east-1" => "/api/clouds/1",
    "eu-west-1" => "/api/clouds/2",
    "us-west-1" => "/api/clouds/3",
    "ap-southeast-1" => "/api/clouds/4",
    "ap-northeast-1" => "/api/clouds/5",
    "us-west-2" => "/api/clouds/6",
    "sa-east-1" => "/api/clouds/7",
    "ap-southeast-2" => "/api/clouds/8",
    "eu-central-1" => "/api/clouds/9",
    "cn-north-1" => "/api/clouds/10",
    "us-east-2" => "/api/clouds/11",
    "ap-northeast-2" => "/api/clouds/12",
    "eu-west-2" => "/api/clouds/13",
    "ca-central-1" => "/api/clouds/14"
  },
  "Azure" => {
    "westus" => "/api/clouds/3518",
    "japaneast" => "/api/clouds/3519",
    "southeastasia" => "/api/clouds/3520",
    "japanwest" => "/api/clouds/3521",
    "eastasia" => "/api/clouds/3522",
    "eastus" => "/api/clouds/3523",
    "westeurope" => "/api/clouds/3524",
    "northcentralus" => "/api/clouds/3525",
    "centralus" => "/api/clouds/3526",
    "canadacentral" => "/api/clouds/3527",
    "northeurope" => "/api/clouds/3528",
    "brazilsouth" => "/api/clouds/3529",
    "canadaeast" => "/api/clouds/3530",
    "eastus2" => "/api/clouds/3531",
    "southcentralus" => "/api/clouds/3532",
    "westus2" => "/api/clouds/3546",
    "westcentralus" => "/api/clouds/3547",
    "uksouth" => "/api/clouds/3567",
    "ukwest" => "/api/clouds/3568",
    "westindia" => "/api/clouds/3569",
    "centralindia" => "/api/clouds/3570",
    "southindia" => "/api/clouds/3571",
    "australiaeast" => "/api/clouds/3537"
  },
  "GCP" => {
    "google" => "/api/clouds/2175"
  }
}
end

###########
# Outputs #
###########

output "output_vpc_id" do
  category "Cloud Account"
  label "VPC ID"
end

output "output_subnet_ids" do
  category "Cloud Account"
  label "Subnet IDs"
end

output "output_account_id" do
  category "Cloud Account"
  label "Cloud Account ID"
end

output "output_temp_password" do
  category "Cloud Account"
  label "Initial CMP Console Password"
end

##############
# Operations #
##############

operation "launch" do
  definition "launch"
  output_mappings do {
    $output_vpc_id => $o_vpc_id,
    $output_subnet_ids => $o_subnet_ids,
    $output_account_id => $o_account_id,
    $output_temp_password => $o_temp_passwd
  } end
end

###############################
# RCL - Operation Definitions #
###############################

define launch($param_account_name, $param_email, $param_ou_lob_parent, $param_provider, $map_cloud_accounts, $map_cloud_regions) return $o_vpc_id, $o_subnet_ids, $o_account_id, $o_temp_passwd do
  # Initialize variables
  $account_id = ""

  ## Outputs
  $o_vpc_id = ""
  $o_subnet_ids = ""
  $o_account_id = ""
  $o_temp_passwd = ""

  # User
  $default_company_name = "ABC Corp."
  $default_company_phone = "867-5309"

  ## Flexera
  $shard = "3"
  $cmp_org_id = "28334"
  $cmp_master_account_id = "125305"
  $refresh_token_cred_name = "REFRESH_TOKEN"
  $rs_access_token = ""
  $child_account_id = ""

  ## AWS
  $aws_account_id = ""
  $iam_access_key = ""
  $iam_secret_access_key = ""
  $aws_network_region = "us-east-1"
  
  ## Azure
  $azure_application_id = "NotNeeded"
  $azure_client_secret = "NotNeeded"
  $azure_tenant_id = "NotNeeded"
  $azure_network_region = "useast"

  ## Google
  $google_network_region = "google"

  ## Network
  $network_name = "CorpDefault"
  $network_cidr = "10.0.0.0/16"
  $network_region = "us-east-1"
  
  ### Subnet
  $subnet_objects = [
    {
      "subnet_name": "Subnet1",
      "subnet_block": "10.0.1.0/24",
      "subnet_availability_zone": "us-east-1a"
    }
  ]

  call start_debugging()

  sub task_label:"Main", on_error: stop_debugging() do
    sub task_label:"Creating Cloud Account" do
      if $param_provider == "AWS"

        # Create AWS Account
        call aws_create_account($param_account_name, $param_email) retrieve $create_response
        $creation_state = "IN_PROGRESS"  #Hardcoding this variable to force the initial get_account_creation_status call
        $creation_id = $create_response["body"]["CreateAccountStatus"]["Id"]

        # Sleep until until account creation is complete
        while $creation_state == "IN_PROGRESS" do
          sleep(10)
          call aws_get_account_creation_status($creation_id) retrieve $creation_status_response
          $creation_state = $creation_status_response["body"]["CreateAccountStatus"]["State"]
          $aws_account_id = $creation_status_response["body"]["CreateAccountStatus"]["AccountId"]
        end

        $account_id = $aws_account_id
        $network_region = $aws_network_region

      elsif $param_provider == "Azure"

        raise "Azure is not yet supported"
        $account_id = uuid()
        $o_temp_passwd = "Pa5sw0rd"
        $network_region = $azure_network_region
        $azure_application_id = cred("AZURE_APPLICATION_ID")
        $azure_client_secret = cred("AZURE_APPLICATION_KEY")
        $azure_tenant_id = cred("AZURE_TENANT_ID")
        
      elsif $param_provider == "GCP"

        raise "Google is not yet supported"
        $account_id = "cloud:company"
        $o_temp_passwd = "Pa5sw0rd"
        $network_region = $aws_network_region
        
      end
    end
  end

  call stop_debugging()
end

######################
# RCL - AWS Specific #
######################

# Creates a new AWS account
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_CreateAccount.html
define aws_create_account($account_name, $email) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=CreateAccount",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.CreateAccount"
    },
    body: {
      "AccountName": $account_name,
      "Email": $email
    }
    )
end

# Gets the status of a account creation job
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_DescribeCreateAccountStatus.html
define aws_get_account_creation_status($creation_id) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=DescribeCreateAccountStatus",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.DescribeCreateAccountStatus"
    },
    body: {
      "CreateAccountRequestId": $creation_id
    }
  )
end

# Retrieves all Root information
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListRoots.html
define aws_list_org_roots() return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=ListRoots",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.ListRoots"
    },
    body: {
      "MaxResults": 1
    }
  )
end

# Retrieves all OUs under the provided parent
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_ListOrganizationalUnitsForParent.html
define aws_list_ous($parent_id) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=ListOrganizationalUnitsForParent",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.ListOrganizationalUnitsForParent"
    },
    body: {
      "ParentId": $parent_id
    }
  )
end

# Creates a new OU
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_CreateOrganizationalUnit.html
define aws_create_ou($parent_id, $ou_name) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=CreateOrganizationalUnit",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.CreateOrganizationalUnit"
    },
    body: {
      "ParentId": $parent_id,
      "Name": $ou_name
    }
  )
end

# Moves an account to a new OU
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_MoveAccount.html
define aws_move_account($account_id, $source_ou_id, $destination_ou_id) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=MoveAccount",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.MoveAccount"
    },
    body: {
      "AccountId": $account_id,
      "SourceParentId": $source_ou_id,
      "DestinationParentId": $destination_ou_id
    }
  )
end

# Attaches a policy to an root, ou, or account
# https://docs.aws.amazon.com/organizations/latest/APIReference/API_AttachPolicy.html
define aws_attach_policy($target_id, $policy_id) return $response do
  $response = http_post(
    url: "https://organizations.us-east-1.amazonaws.com/?Version=2016-11-28&Action=AttachPolicy",
    signature: { "type": "aws" },
    headers: {
      "content-type": "application/x-amz-json-1.1",
      "X-Amz-Target": "AWSOrganizationsV20161128.AttachPolicy"
    },
    body: {
      "TargetId": $target_id,
      "PolicyId": $policy_id
    }
  )
end

# Assumes a role
# https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
define aws_assume_role($role_arn, $role_session_name) return $response do
  $response = http_post(
    url: "https://sts.amazonaws.com/?Version=2011-06-15&Action=AssumeRole&RoleArn="+$role_arn+"&RoleSessionName="+$role_session_name,
    signature: { "type": "aws"}
  )
end

# Creates a new IAM user
# https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateUser.html
define aws_create_iam_user($username, $access_key, $secret_access_key, $session) return $response do
  $response = http_post(
    url: "https://iam.amazonaws.com/?Action=CreateUser&UserName="+$username+"&Version=2010-05-08",
    signature: {
      "type": "aws",
      "access_key": $access_key,
      "secret_key": $secret_access_key
    },
    headers: {
      "x-amz-security-token": $session
    }
  )
end

# Attaches a policy to a user
# https://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachUserPolicy.html
define aws_attach_user_policy($policy_arn, $username, $access_key, $secret_access_key, $session) return $response do
  $response = http_post(
    url: "https://iam.amazonaws.com/?Action=AttachUserPolicy&Version=2010-05-08&PolicyArn="+$policy_arn+"&UserName="+$username,
    signature: {
      "type": "aws",
      "access_key": $access_key,
      "secret_key": $secret_access_key
    },
    headers: {
      "x-amz-security-token": $session
    }
  )
end

# Creates new API credentials for a user
# https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateAccessKey.html
define aws_create_access_key($username, $access_key, $secret_access_key, $session) return $response do
  $response = http_post(
    url: "https://iam.amazonaws.com/?Action=CreateAccessKey&Version=2010-05-08&UserName="+$username,
    signature: {
      "type": "aws",
      "access_key": $access_key,
      "secret_key": $secret_access_key
    },
    headers: {
      "x-amz-security-token": $session
    }
  )
end

#################
# RCL - CMP API #
#################

# Creates a CMP account
# https://docs.rightscale.com/api/api_1.5_examples/childaccounts.html
# https://reference.rightscale.com/api1.5/resources/ResourceChildAccounts.html
define cmp_create_child_acct($account_name, $shard, $access_token, $cmp_account_id) return $account_href do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/child_accounts",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token,
      "content-type": "application/json"
    },
    body: {
      "child_account": {
        "cluster_href": "/api/clusters/"+$shard,
        "name": $account_name
        }
    }
  )
  $account_href = $response["headers"]["Location"]
end

# Retrieves the current account's account number
# https://reference.rightscale.com/api1.5/resources/ResourceSessions.html
define cmp_find_account_number() return $account_id do
  $session = rs_cm.sessions.index(view: "whoami")
  $account_id = last(split(select($session[0]["links"], {"rel":"account"})[0]["href"],"/"))
end

# Retrieves the shard a CMP account exists in
# https://reference.rightscale.com/api1.5/resources/ResourceAccounts.html
define cmp_find_shard($account_id) return $shard_number do
  $account = rs_cm.get(href: "/api/accounts/" + $account_id)
  $shard_number = last(split(select($account[0]["links"], {"rel":"cluster"})[0]["href"],"/"))
end

# Creates a CMP oauth2 access token
# https://docs.rightscale.com/api/api_1.5_examples/oauth.html
# https://reference.rightscale.com/api1.5/resources/ResourceOauth2.html
define cmp_generate_access_token($shard, $refresh_token_cred) return $response, $access_token do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/oauth2",
    headers:{"X-API-Version": "1.5"},
    body:{
      "grant_type": "refresh_token",
      "refresh_token": cred($refresh_token_cred)
    }
  )
  $access_token = $response['body']['access_token']
end

# Creates a new cloud account
# https://docs.rightscale.com/api/api_1.5_examples/cloudaccounts.html
# https://reference.rightscale.com/api1.5/resources/ResourceCloudAccounts.html
define cmp_create_cloud_acct($shard, $cmp_account_id, $access_token, $cloud_id, $creds) return $response do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/cloud_accounts",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token,
      "content-type": "application/json"
    },
    body: {
      "cloud_account": {
        "cloud_href": "/api/clouds/"+$cloud_id,
        "creds": $creds
        }
    }
  )
end

# Checks to see if a user is affiliated with an org
# https://reference.rightscale.com/governance-iam/#/2.0/controller/V2-Definitions-OrgUsers/index
define cmp_check_user($cmp_org_id, $access_token, $email) return $response do
  $response = http_get(
    url: "https://governance.rightscale.com/grs/orgs/"+$cmp_org_id+"/users?filter=email="+$email,
    headers: {
      "X-Api-Version": "2.0",
      "Authorization": "Bearer "+ $access_token
    }
  )
end

# Creates a new user
# https://docs.rightscale.com/api/api_1.5_examples/users.html
# https://reference.rightscale.com/api1.5/resources/ResourceUsers.html
define cmp_create_user($company, $email, $first_name, $last_name, $password, $phone) return @user do
  @user = rs_cm.users.create(user: {company: $company, email: $email, first_name: $first_name, last_name: $last_name, password: $password, phone: $phone})
end

# Creates a new permissions assignment
# https://docs.rightscale.com/api/api_1.5_examples/permissions.html
# https://reference.rightscale.com/api1.5/resources/ResourcePermissions.html
define cmp_create_permission($shard, $cmp_account_id, $access_token, $user_href, $role_title) return $response do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/permissions",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    },
    body: {
      "permission": {
        "role_title": $role_title,
        "user_href": $user_href
      }
    }
  )
end

# Creates a new network
# https://reference.rightscale.com/api1.5/resources/ResourceNetworks.html
define cmp_create_network($shard, $cmp_account_id, $access_token, $payload) return $response do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/networks",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    },
    body: $payload
  )
end

# Get CMP resource based on href
# https://reference.rightscale.com/api1.5/index.html
define cmp_get_cm_resource($shard, $cmp_account_id, $access_token, $href) return $response do
  $response = http_get(
    url: "https://us-"+$shard+".rightscale.com"+$href,
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    }
  )
end

# Retrieves a datacenter based on name
# https://reference.rightscale.com/api1.5/resources/ResourceDatacenters.html
define cmp_get_datacenter($shard, $cmp_account_id, $access_token, $cloud_href, $datacenter_name) return $response do
  $response = http_get(
    url: "https://us-"+$shard+".rightscale.com"+$cloud_href+"/datacenters?filter[]=name=="+$datacenter_name,
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    }
  )
end

# Creates a new subnet
# https://reference.rightscale.com/api1.5/resources/ResourceSubnets.html
define cmp_create_subnet($shard, $cmp_account_id, $access_token, $cloud_href, $payload) return $response do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com"+$cloud_href+"/subnets",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    },
    body: $payload
  )
end

# Creates a new CMP credential
# https://reference.rightscale.com/api1.5/resources/ResourceCredentials.html
define cmp_create_credential($shard, $cmp_account_id, $access_token, $payload) return $response do
  $response = http_post(
    url: "https://us-"+$shard+".rightscale.com/api/credentials",
    headers: {
      "X-API-Version": "1.5",
      "X-Account": $cmp_account_id,
      "Authorization": "Bearer "+ $access_token
    },
    body: $payload
  )
end

################
# RCL - System #
################

# Starts capturing debug information
# Use with 'stop_debugging()'
define start_debugging() do
  if $$debugging == false || logic_and($$debugging != false, $$debugging != true)
    initiate_debug_report()
    $$debugging = true
  end
end

# Stops capturing debug information and sends the debug log to audit entries
# Requires sys_log package
# Use with 'start_debugging()'
define stop_debugging() do
  if $$debugging == true
    $debug_report = complete_debug_report()
    call sys_log.detail($debug_report)
    $$debugging = false
  end
end
