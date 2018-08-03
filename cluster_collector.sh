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
for peer in $(cat peers_file);
do
    echo "Starting pod $peer"
    kubectl cp node_collector.sh $peer:/node_collector.sh
    kubectl exec -it $peer -- bash node_collector.sh
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
tar -zvcf $result_file -C $INFO_DIR .
rm -r $INFO_DIR
rm peers_file

echo "Process complete. File generated : " $result_file