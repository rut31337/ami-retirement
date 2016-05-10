#!/bin/bash

# Delete AMIs and Snapshots older than $daysAgo days.
daysAgo=15

daysAgoISO=`date +"%Y%m%d" --date="$daysAgo days ago"`
echo "Deleting AMIs and Snapshots older than: $daysAgoISO"

# Space delimited list of regions to work in
REGIONS="us-east-1 us-west-1 us-west-2"

# Location of aws binary
AWS="/usr/local/bin/aws"

#IMAGES:x86_64:2016-04-21T01:15:25.000Z:Automatic_backup_of_ipa3.opentlc.com_as_of_2016-04-21_01:15:xen:ami-019e6f61:719622469867/autobackup-ipa3.opentlc.com-2016-04-21-01-15:machine:autobackup-ipa3.opentlc.com-2016-04-21-01-15:719622469867:False:/dev/sda1:ebs:simple:available:hvm
#BLOCKDEVICEMAPPINGS:/dev/sda1
#EBS:True:False:snap-b898a2fb:32:gp2

remove() {
	if [ $imageDate -lt $daysAgoISO ]
	then
		echo "Remove AMI: $image created: $imageDate"
		$AWS --region $REGION --output table ec2 deregister-image --image-id $image
		for snap in $bdList
		do
			echo "Remove SNAP: $snap"
			$AWS --region $REGION --output table ec2 delete-snapshot --snapshot-id $snap
		done
	fi
}

for REGION in $REGIONS
do
  echo $REGION
  image=""
  first=1
  for line in `$AWS --output text --region $REGION ec2 describe-images --filters Name=name,Values=autobackup-*|egrep -v "^TAGS|^BLOCKDEVICEMAPPINGS"|sed 's/\t/:/g'|sed 's/ /_/g'`
  do
	if [[ $line =~ ^IMAGES: ]]
	then
 		if [ $first == 0 ]
		then
			remove
		fi
		image=`echo $line|sed 's/.*:ami/ami/'|cut -f1 -d:`
		#rimageDate=`echo $line|cut -f3 -d:`
		#ln=`echo -n $rimageDate|wc -c`
		#((pos=$ln - 16))
		#imageDate=`echo $rimageDate |cut -c $pos-|cut -f1-4 -d- | sed 's/-//g'`
		imageDate=`echo $line|cut -f3 -d:|cut -f1 -dT|sed 's/-//g'`
		bdList=""
		#echo $image
		#echo $imageDate
		first=0
	elif [[ $line =~ ^EBS: ]]
	then
		bd=`echo $line|cut -f4 -d:`
		bdList="$bdList $bd"
	else
		echo "Error $line was unexpected"
		exit 1
	fi
  done
done
