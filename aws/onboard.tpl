#!/bin/bash

# BIG-IPS ONBOARD SCRIPT

LOG_FILE=${onboard_log}

# if [ ! -e $LOG_FILE ]
# then
#      touch $LOG_FILE
#      exec &>>$LOG_FILE
# else
#     #if file exists, exit as only want to run once
#     exit
# fi
#
#exec 1>$LOG_FILE 2>&1

# CHECK TO SEE NETWORK IS READY
CNT=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

### DOWNLOAD ONBOARDING PKGS
# Could be pre-packaged or hosted internally

admin_username='${uname}'
admin_password='${upassword}'
CREDS="admin:"$admin_password
DO_URL='${DO_onboard_URL}'
DO_FN='${basename(DO_onboard_URL)}'
AS3_URL='${AS3_URL}'
AS3_FN='${basename(AS3_URL)}'

mkdir -p ${libs_dir}

echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
curl -L  $DO_URL -o ${libs_dir}/$DO_FN

echo -e "\n"$(date) "Download AS3 Pkg"
curl -L  $AS3_URL -o ${libs_dir}/$AS3_FN
sleep ${management_interface_delay}

# Copy the RPM Pkg to the file location
cp ${libs_dir}/*.rpm /var/config/rest/downloads/

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
curl -u $CREDS -X POST http://localhost:8100/mgmt/shared/iapp/package-management-tasks -d $DATA