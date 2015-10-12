#!/bin/bash

########################################################################################################
#
# Copyright (c) 2014, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
# DESCRIPTION
#
#	This script reads a CSV of usernames and email addresses and imports them to the JSS.
#	The format must be username in the first column and email address in the second
#
####################################################################################################
#
# HISTORY
#
#  	-Created by Sam Fortuna, JAMF Software, LLC, on June 18th, 2014
#	-Updated by Sam Fortuna, JAMF Software, LLC, on August 5th, 2014
#		-Improved error handling
#		-Returns a list of failed submissions
#	-Updated by TJ Bauer, JAMF Software, LLC, on September 9th, 2014
#		-Improved reading of file
#   -Updated by Peter Loobuyck, Switch on October 12th, 2015
#       -Added interaction to secure the script
#		-Added option to add Full Name
#
####################################################################################################

#Variables
file=$1										#Path to the CSV as argument


#Option to read in the path from Terminal
if [[ "$file" == "" ]]; then
	echo "Please add the path to the CSV as argument"
	exit 0
fi

#Verify we can read the file
data=`cat $file`
if [[ "$data" == "" ]]; then
	echo "Unable to read the file path specified"
	echo "Ensure there are no spaces and that the path is correct"
	exit 1
fi

echo "Now we'll ask for some information to log on. Server has to have fqdn and if needed instance and port. Default is 443."
read -p 'Enter server: ' server
read -p 'Enter jss admin user : ' username
read -sp 'Enter jss password: ' password
echo -n "Do you want to import Full Name as a third column (y/n)? "
read answer
if echo "$answer" | grep -iq "^y" ;then
    addfull=1
fi
#Set a counter for the loop
counter="0"

duplicates=[]
#Loop through the CSV and submit data to the API
while read name
do
	counter=$[$counter+1]
	line=`echo "$data" | head -n $counter | tail -n 1`
	user=`echo "$line" | awk -F , '{print $1}'`
	email=`echo "$line" | awk -F , '{print $2}'`
	if [[ "$addfull" == "1" ]]; then 
		fullname=`echo "$line" | awk -F , '{print $3}'`
	fi
	
	echo "Attempting to create user - $fullname: id $user - $email"
	
	#Construct the XML
	if [[ "$addfull" == "1" ]]; then 
		apiData="<user><name>${user}</name><email>${email}</email><full_name>${fullname}</full_name></user>"
	else
		apiData="<user><name>${user}</name><email>${email}</email></user>"
	fi
	
	output=`curl -k -u $username:$password -H "Content-Type: text/xml" https://$server/JSSResource/users/id/0 -d "$apiData" -X POST`

	#Error Checking
	error=""
	error=`echo $output | grep "Conflict"`
	if [[ $error != "" ]]; then
		duplicates+=($user)
	fi
done < $file

echo "The following users could not be created:"
printf -- '%s\n' "${duplicates[@]}"

exit 0
