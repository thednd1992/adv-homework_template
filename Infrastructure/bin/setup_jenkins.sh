#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

oc project $GUID-jenkins

oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=3Gi --param VOLUME_CAPACITY=6Gi -n ${GUID}-jenkins
oc rollout pause dc jenkins -n ${GUID}-jenkins
oc set resources dc jenkins --limits=memory=4Gi,cpu=2 --requests=memory=2Gi,cpu=1 -n ${GUID}-jenkins
oc rollout resume dc jenkins -n ${GUID}-jenkins

while : ; do
    echo "Checking if Jenkins is Ready..."
    oc get pod -n ${GUID}-jenkins | grep -v deploy | grep "1/1"
    if [ $? == "1" ] 
      then 
      echo "Waiting 10 seconds..."
        sleep 10
      else 
        break 
    fi
done

oc new-build --name=jenkins-slave-appdev --dockerfile=$'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\nUSER root\nRUN yum -y install skopeo apb && \yum clean all\nUSER 1001' -n ${GUID}-jenkins


while : ; do
	echo "Checking if Jenkins-app-slave is Ready..."
	oc get pod -n ${GUID}-jenkins | grep 'slave' | grep "Completed"
	if [ $? == "0" ] 
		then 
		echo 'jenkins-slave-appdev build completed'
		break
	else 
		echo 'Waiting 10 seconds...'
		sleep 10
	fi
done

oc create configmap basic-config --from-literal="GUID=${GUID}" --from-literal="REPO=${REPO}" --from-literal="CLUSTER=${CLUSTER}"

oc create -f Infrastructure/templates/buildconfig-mlbparks.yml -n ${GUID}-jenkins
oc create -f Infrastructure/templates/buildconfig-nationalparks.yml -n ${GUID}-jenkins
oc create -f Infrastructure/templates/buildconfig-parksmap.yml -n ${GUID}-jenkins

oc set env bc/mlbparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/nationalparks-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
oc set env bc/parksmap-pipeline GUID=${GUID} REPO=${REPO} CLUSTER=${CLUSTER} -n ${GUID}-jenkins
