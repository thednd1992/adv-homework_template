#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# Implemented by vbaum

sleep 120

oc project $GUID-nexus 
oc process -f Infrastructure/templates/template-nexus.yml -n ${GUID}-nexus -p GUID=${GUID} | oc create -n ${GUID}-nexus -f -
oc expose svc nexus3 -n ${GUID}-nexus
oc expose svc nexus-registry -n ${GUID}-nexus

while : ; do
	echo "Checking if Nexus is Ready..."
    oc get pod -n ${GUID}-nexus | grep '\-1\-' | grep -v deploy | grep "1/1"
    if [ $? == "1" ] 
      then 
      echo "Sleeping 10 seconds."
        sleep 10
      else 
        break 
    fi
done

oc get routes -n $GUID-nexus
sleep 60

curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh

chmod +x setup_nexus3.sh

sh setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n ${GUID}-nexus )
rm -f setup_nexus3.sh
oc get routes -n $GUID-nexus