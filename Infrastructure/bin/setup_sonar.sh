#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# Implemented by vbaum

oc project $GUID-sonarqube 

sleep 60

oc process -f Infrastructure/templates/template-sonarqube.yml -n ${GUID}-sonarqube -p GUID=${GUID} | oc create -n ${GUID}-sonarqube -f -

while : ; do
    echo "Checking if Sonarqube is Ready..."
    oc get pod -n ${GUID}-sonarqube | grep "sonarqube" | grep -v deploy | grep "1/1"
    if [ $? == "1" ] 
      then 
      echo "Waiting 10 seconds..."
        sleep 10
      else 
        break 
    fi
done
