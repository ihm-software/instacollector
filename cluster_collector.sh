#!/bin/bash

#GLOBAL VARIABLES
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFO_DIR=/tmp/InstaCollection_$(date +%Y%m%d%H%M)
ENV_NAME=`kubectl config get-contexts -o name`

kubectl get pods | grep ihm-inventory-cassandra | awk '{print $1;}' > peers_file

wait

mkdir $INFO_DIR

echo "Found these pods"
cat peers_file

#Execute the node_collector on each node
while read -r peer
do
    echo "Starting pod $peer"
    kubectl exec -t $peer -- sh -c `cat node_collector.sh`
    sleep 10
    echo "Finished pod $peer"
    echo "Getting files from $peer"
    mkdir $INFO_DIR/$peer
    kubectl cp $peer:/tmp/InstaCollection.tar.gz $INFO_DIR/$peer/InstaCollection_$peer.tar.gz
    echo "Finished getting files from $peer"
done < peers_file

#waiting for all node_collectors to complete
wait

#compress the info directory 
result_file=./InstaCollection_$(echo $ENV_NAME)_$(date +%Y%m%d%H%M).tar.gz
tar -zcf $result_file -C $INFO_DIR .
rm -r $INFO_DIR
rm peers_file

echo "Process complete. File generated : " $result_file