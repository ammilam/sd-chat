# Jira to Hangouts Chat Integration Using Google Cloud Functions


# Overview

Having real-time notifications for the various projects and work streams happening across DaVita is imperative to the success of our organization. With the decision to use Google Hangouts Chat as the replacement client for Hipchat, a high priority need arose to integrate it with the various enterprise applications used in-house to track work. This document covers details around the Jira and Hangouts Chat Integration, which is composed of three parts combined into a single Terraform Deployment:



1. A Hangouts Chat room webhook
2. A Google Cloud Function deployed from Google Cloud Source Repository that is stored as code in the DaVita BitBucket instance - [repo link](https://bitbucket.davita.com/projects/JTD/repos/terraform-deployment-source/browse)
3. A corresponding Jira webhook that posts to the URL provided as the Google Cloud Function listener

Prerequisites




*   Have access to Terraform/Consul/Vault
*   Access to [Hangouts Chat](chat.google.com)
*   Access to [Jira](https://jira.davita.com)


# Terraform

The integration is handled entirely by Terraform. Below are the phases…


## Configuring Terraform



1. Download latest from [https://github.com/fourplusone/terraform-provider-jira/releases](https://github.com/fourplusone/terraform-provider-jira/releases) 
2. Unzip terraform-provider-jira.zip and move contents to  ~/.terraform.d/plugins/


## Preparing the Deployment



1. Get a Hangouts Chat webhook url as detailed below
2. Fork the following [repo](https://bitbucket.davita.com/scm/jtd/terraform-deployment-source.git ) into the [Jira-CF-Chat Terraform Deployments](https://bitbucket.davita.com/projects/JTD) project in Bitbucket. Name it after the room Jira is integrating with (**hangouts-room-name**) 
3. In **terraform.tfvars** fill out the following
    1. **created_by** = "who created the function"
    2. **owner** = "who maintains it"
    3. **function_name** = "name of function"
    4. **env_variables** = {URL = "hangouts chat webhook url"}
    5. **jql** = “JQL for the Jira webhook”
    6. **jira_events** = [“jira:issue_created”, “jira:issue_updated”]
4. In **backend.tf** modify the following with the **name **passed in **function_name** above
    1. path    = "terraform/davita_org/gcp/base/projects/{**function_name}**/tfstate"
5. Download the repo to your local machine



## Deploying the Integration

Run the following in terminal.. \




1. **export VAULT_ADDR=[https://platform-vault.davita.com/](https://platform-vault.davita.com/)**
2. **vault login -method=ldap**
3. From the previous statements response copy the token received in output and run the following    -   **export VAULT_TOKEN=tokenFromLastStatement**
4. **source init-functions.sh**
5. **terraform init**
6. **terraform plan/apply**




# Hangouts Chat Room Webhook

Creating a Hangouts Chat webhook is pretty straightforward and is done in app…




1. Open up the room needing to receive notifications from Jira and click the name Icon
2. Click Configure Webhooks
3. Click add and enter a name
4. Copy and make note of the webhook url


Deploy Google Cloud Function

In order for this integration to be successful the following needs to be set when deploying a function…




*   Trigger - **http**
*   Runtime - **nodejs8**
*   Allow unauthenticated invocation
*   Source - cloud source repository that has code from this [repo link](https://bitbucket.davita.com/projects/SDLC/repos/gcp-cloudfunction-jira-hangouts-int/browse)
*   Entry point/function - **jiraGp2**
*   Environment Variable URL set to the Hangouts Chat webhook created above



## Deploy from Terminal

Either from within gcloud terminal, or from a local terminal - you can execute the following to deploy a new cloud function:



```
gcloud functions deploy FUNCTION_NAME \
--trigger-http \
--runtime nodejs8 \
--allow-unauthenticated \
--source https://source.developers.google.com/projects/{PROJECT_NAME}/repos/{REPO_NAME}/moveable-aliases/master/paths/ \
--entry-point jiraGp2 \
--timeout 120 \
--set-env-vars URL='CHAT_WEBHOOK_URL'
```




*   Replace **FUNCTION_NAME** with the name of the function being deployed
*   Replace **PROJECT_NAME** and **REPO_NAME** with the corresponding information from google cloud source repository
*   Replace **CHAT_WEBHOOK_URL** with the webhook url from the step above. URL **must** be surrounded by ‘single quotes’


### Terminal Response
`


```
Deploying function (may take a while - up to 2 minutes)...done.                
availableMemoryMb: 256
entryPoint: jiraGp2
environmentVariables:
  URL: 'https://chat.googleapis.com/v1/spaces/AAAA4hsLpwU/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI
httpsTrigger:
  url: https://us-central1-cloudfunctionforchat.cloudfunctions.net/test-for-new-repo
labels:
  deployment-tool: cli-gcloud
name: projects/cloudfunctionforchat/locations/us-central1/functions/test-for-new-repo
runtime: nodejs8
serviceAccountEmail: cloudfunctionforchat@appspot.gserviceaccount.com
sourceRepository:
  deployedUrl: https://source.developers.google.com/projects/cloudfunctionforchat/repos/gcp-cloudfunction-jira-hangouts-int/revisions/84482ad5d571e215f79092e28fd50cff7c1e2e96/paths/
  url: https://source.developers.google.com/projects/cloudfunctionforchat/repos/gcp-cloudfunction-jira-hangouts-int/moveable-aliases/master/paths/
status: ACTIVE
timeout: 120s
updateTime: '2020-01-02T23:35:57Z'
versionId: '1'
```


Make note of` httpsTrigger`



Deploy from Cloud Console



1. Go to [Cloud Functions Overview page](https://console.cloud.google.com/functions/list) in the Cloud Console.
2. Click **Create function**
3. Name function in a manner that reflects what Jira Project and Hangouts Chat room it is integrating
4. Create function using the settings detailed above in the Deploy Cloud Function section


# Creating a Jira Webhook

[Jira webhooks](https://developer.atlassian.com/server/jira/platform/webhooks/) can be created either by sending an HTTP request, or through the webhooks portion of the admin console in app (Jira administration console > System > Webhooks). Webhooks **<span style="text-decoration:underline;">must</span>** have a unique name when created.


## HTTP Request Jira webhook creation

Send an HTTP request modeled after the one below containing a unique webhook name, the url of the Cloud Function listener, Jira webhook events, and the [JQL](https://www.atlassian.com/blog/jira-software/jql-the-most-flexible-way-to-search-jira-14) identifying a particular subset of projects/issues in jira related to the integration.


```
curl --location --request POST 'https://username:password@jira.davita.com/rest/webhooks/1.0/webhook' \
--header 'Content-Type: application/json' \
--data-raw '{
  "name": "NAME_OF_WEBHOOK",
  "url": "CLOUD_FUNCTION_LISTENER",
  "events": [
    "jira:issue_created",
    "jira:issue_updated"
  ],
  "filters": {
     "issue-related-events-section": "JIRA_QUERY"
  },
  "excludeBody" : false
  }'
```




*   Replace **NAME_OF_WEBHOOK** with the appropriate name, should reflect what Project is being Integrated with a Hangouts Chat Room
*   Replace **CLOUD_FUNCTION_LISTENER** with the URL of the listener created by 



[Deploying a Cloud Function](#heading=h.lx6qsqoovizj)
*   Replace **JIRA_QUERY** with the [JQL](https://www.atlassian.com/blog/jira-software/jql-the-most-flexible-way-to-search-jira-14) pointing to a specific subset of Projects/Issues in Jira. 


## Registering a webhook via the Jira administration console



1. Go to Jira administration console > System > Webhooks (in the Advanced section).
You can also use the quick search (keyboard shortcut is .), then type 'webhooks'. 
2. Click Create a webhook.
3. Assign the cloud function listener URL created by Deploying a Cloud Function
4. Name webhook to match project and integration being supported
5. Use [JQL](https://www.atlassian.com/blog/jira-software/jql-the-most-flexible-way-to-search-jira-14) to specify the project(s) and issue(s) that will trigger the function
6. Select webhook events, like: ‘issue created’, ‘issue updated’
7. Click **Create** 



# Cloud Function Source Code 

[https://bitbucket.davita.com/projects/SDLC/repos/gcp-cloudfunction-jira-hangouts-int/browse/index.js](https://bitbucket.davita.com/projects/SDLC/repos/gcp-cloudfunction-jira-hangouts-int/browse/index.js) \



```
const request = require('request');
require('dotenv').config();

  //jiraGp2 is the entry point for the function
exports.jiraGp2 = (req, res) => {

  //process.env.URL pulls in URL environment variable deployed with Cloud Function
        var url = process.env.URL;

  //sets variables for the json payload received from the Jira webhook
	var postbody = req.body;
	var verb = ' updated ';
	var user;
	var issue;
	var who;
	var bodytext = '';
        console.log('firing webhook');

  //logs the payload if uncommented
  //console.log(req.body);
        

        const data = req.body;
	console.log('2. data webhookevent is' + data.webhookEvent);
	if (data.issue) {
		user = data.user;
		who = user.displayName;
		issue = data.issue;
               
		baseJiraUrl = issue.self.replace(/\/rest\/.*$/, '');
		issue_url = baseJiraUrl + '/browse/' + issue.key;
      
                //looks for jira webhook events and formats body text accordingly
		if ('jira:issue_created'===data.webhookEvent) {
			verb = '*Created* ';
			bodytext = '*Description*: ' +issue.fields.description;
		} else if ('jira:issue_deleted'===data.webhookEvent) {
			verb = '*Deleted* ';
		} else if ('jira:issue_updated'===data.webhookEvent) {
			if ('issue_commented'===data.issue_event_type_name) {
				verb = '*Commented* on ';
				bodytext = '*Comment*: ' +data.comment.body;
			} else {
				return;
			}
		} else {
			return;
		}

		postbody = "*" + who + "*" + "\n";
		postbody = postbody + verb + "<" + issue_url + "|" +  issue.key +">"  + ': ' + issue.fields.summary + "\n";
		postbody = postbody + bodytext;

		//sends formatted payload to the Hangouts Chat room webhook passed in the URL variable
		request.post({url:url, body:JSON.stringify({"text":postbody})}, function optionalCallback(err, httpResponse, body) {
			if (err) {
				res.send('Error' + err);
				return console.error('upload failed:', err);
			}
			console.log('Upload successful!  Server responded with:', body);
		});
	}
	res.send({"text":postbody});
    //console.log ("7. Outside the if.  the postbody is " + postbody);
};
```


References 



*   Hangouts Chat Webhook Documentation [https://developers.google.com/hangouts/chat/how-tos/webhooks](https://developers.google.com/hangouts/chat/how-tos/webhooks)
*   Bitbucket Repo: [https://bitbucket.davita.com/projects/SDLC/repos/gcp-cloudfunction-jira-hangouts-int/browse](https://bitbucket.davita.com/projects/SDLC/repos/gcp-cloudfunction-jira-hangouts-int/browse)
*   Link to Jira Webhooks in Admin Console: [https://jira.davita.com/plugins/servlet/webhooks](https://jira.davita.com/plugins/servlet/webhooks)
*   Google Cloud Function Documentation: [https://cloud.google.com/functions/docs/](https://cloud.google.com/functions/docs/)
*   Google Cloud Source Repository Documentation: [https://cloud.google.com/source-repositories/docs/](https://cloud.google.com/source-repositories/docs/)
*   Jira Webhook Documentation: [https://developer.atlassian.com/server/jira/platform/webhooks/](https://developer.atlassian.com/server/jira/platform/webhooks/)
