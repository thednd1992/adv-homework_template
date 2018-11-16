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
oc process -f Infrastructure/templates/template-sonarqube.yml -n ${GUID}-sonarqube -p GUID=${GUID} | oc create -n ${GUID}-sonarqube -f -
