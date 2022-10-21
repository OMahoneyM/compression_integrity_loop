#!/bin/bash

# absolute path that contains the fastq.gz files to be checked
DIR="/Users/omahoneym/Desktop/GenSkim_AC/test2/"

# Outputs a log file in the same directory as the script
# exec > >(tee $DIR"comp_check.log") 2>&1

# creates a variable containing all .gz files
FILES=$DIR"*.gz"

# count # of .gz files in directory
file_count=$(ls $FILES | wc -l)
# initiate counter
COUNTER=0

# for loop that passes each file to gzip for an integriy checked
# if it passes the file name is added to comp_check.log
# if it fails the file name is added to comp_check_error.log
# a directory called corrupt files is created in the $DIR path and
# the corrupt files are moved into it along with the error log.
for f in $FILES
do
	COUNTER=$[COUNTER + 1]
	name="$(basename -- $f)"
	if gzip -t -q $f; then
		echo $name >> $DIR"comp_check.log"
	else
		echo $name >> $DIR"comp_check_error.log"
		if [ -d $DIR"corrupt_files" ]
		then
			:
		else
			mkdir $DIR"corrupt_files"
		fi
		mv $f $DIR"corrupt_files"
	fi
	echo "[ "$COUNTER" /"$file_count" ]"
done

# move error log into folder with corrupt files
mv $DIR"comp_check_error.log" $DIR"corrupt_files"
