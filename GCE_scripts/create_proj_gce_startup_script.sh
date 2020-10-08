#!/bin/bash
#-----------------------------------
# Bash script to do the following
# 1/ Create a GCP project
# 2/ Create a GCP GCE with a startup script & defined META-DATA
# 3/ META-DATA is the GS bucket name
# 4/ Read the log file from the META-DATA bucket
#-----------------------------------
set -x

# Create a new Project ID
echo -ne "Enter New Project name...\n" ; read PROJECT_NAME
echo "Creating Project with Name : " $PROJECT_NAME

gcloud projects create $PROJECT_NAME

if [ $? -eq 0 ]
then
	echo "---------------------------------------"
	PROJECT_ID=$(gcloud projects list --filter="name:$PROJECT_NAME" --format="value(projectId)")
	echo "Project created successfully. Project ID - " $PROJECT_ID
	gcloud config set project $PROJECT_ID 
	echo "Project Set as : " $(gcloud config get-value project)
else
	echo "Failed to create project, exiting..."
	exit 1
fi	

# Enable Billing for Project
echo "---------------------------------------"
echo "Enabling billing"
echo "---------------------------------------"
BILLING_ID=$(gcloud alpha billing accounts list --format="value(ACCOUNT_ID)")
echo "Billing account : " $BILLING_ID

gcloud alpha billing projects link $PROJECT_ID --billing-account=$BILLING_ID
if [ $? -eq 0 ]
then
	echo "Billing enabled.."
else
	echo "Error during enabling billing, exiting..."
	exit 1
fi

# Create a new GCE instance with META-DATA as log file bucket name
bucket_name_metadata="lab-logs-bucket"
bucket_name='gs://sc-startup-script-logs-1/'
startup_script_name='gce_startup_script.sh'

# Create bucket 
echo "---------------------------------------"
echo "           Create bucket  "
echo "---------------------------------------"
gsutil mb $bucket_name
if [ $? -eq 0 ]
then
	echo "Created bucket..."
	# Reading bucket contents
	echo "---------------------------------------"
	echo "   Reading bucket contents "
	echo "---------------------------------------"
	gsutil ls $bucket_name
else
	echo "Error during creating bucket, exiting..."
	exit 1
fi


# Create the instance 
echo "---------------------------------------"
echo "   Create the GCE instance "
echo "---------------------------------------"
gcloud compute instances create \
	--scopes=compute-rw,datastore,logging-write,monitoring-write,storage-full,trace \
	--metadata="lab-logs-bucket"=$bucket_name  \
	--metadata-from-file=startup-script=gce_startup_script.sh \
	gsdk-sh-1


echo "---------------------------------------"
echo -e "   Please wait for 5 mins to complete the startup-script and then run \ngsutil ls $bucket_name"
echo "---------------------------------------"

