#!/bin/bash

# Delete AMIs and Snapshots older than $daysAgo days.
daysAgo=15

daysAgoISO=`date +"%Y%m%d" --date="$daysAgo days ago"`
echo "Deleting AMIs and Snapshots older than: $daysAgoISO"

# Sample data
#IMAGE:ami-7d3e5c18:719622469867/autobackup-host.example.com-2015-09-05-01-15:719622469867:available:private::x86_64:machine:aki-1eceaf77:::ebs:/dev/sda1:paravirtual:xen
#BLOCKDEVICEMAPPING:EBS:/dev/sda1::snap-af725de1:45:true:gp2::Not_Encrypted
#BLOCKDEVICEMAPPING:EBS:/dev/sdb::snap-e6cf169c:45:true:gp2::Not_Encrypted
#TAG:image:ami-7d3e5c18:name:autobackup-host.example.com-2015-09-05-01-15

image=""

for line in `ec2-describe-images -F name=autobackup-*|sed 's/\t/:/g'|sed 's/ /_/g'`
do
	if [[ $line =~ ^IMAGE: ]]
	then
		image=`echo $line|cut -f2 -d:`
		rimageDate=`echo $line|cut -f3 -d:`
		ln=`echo -n $rimageDate|wc -c`
		((pos=$ln - 16))
		imageDate=`echo $rimageDate |cut -c $pos-|cut -f1-4 -d- | sed 's/-//g'`
		bdList=""
	elif [[ $line =~ ^BLOCKDEVICEMAPPING: ]]
	then
		bd=`echo $line|cut -f5 -d:`
		bdList="$bdList $bd"
	elif [[ $line =~ ^TAG: ]]
	then
		if [ $imageDate -lt $daysAgoISO ]
		then
			echo "Remove AMI: $image created: $imageDate"
			ec2-deregister $image
			for snap in $bdList
			do
				echo "Remove AMI: $image SNAP $snap"
				ec2-delete-snapshot $snap
			done
		fi
	else
		echo "Error $line was unexpected"
		exit 1
	fi
done
