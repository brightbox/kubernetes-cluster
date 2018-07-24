#!/bin/sh
# Recover the subject from a base64 encoded kubernetes client certificate
# 
# extract-subject kubeconfig
#

if [ "$#" -ne 1 ]
then
	echo "Usage: $(basename $0) kubeconfig" >&2
	exit 1
elif [ ! -r "$1" ]
then
	echo "Unable to open $1 for reading" >&2
	exit 2
fi
awk '/client-certificate-data/ { print $2 }' "$1" | base64 -d | openssl x509 -noout -subject
