#!/bin/bash

# Set the absolute path containing the .gz files to be checked
DIR=""

# creates a variable containing all .gz files
FILES=${DIR}"*.gz"

# count # of .gz files in directory
file_count=$(ls $FILES | wc -l)

# initiate counter
COUNTER=0

# for loop that passes each .gz file to the gzip software to test
# its integrity. If it passes the file name is added to comp_check.log
# If it fails the file name is added to comp_check_error.log
# A directory called "corrupt files" is created in the input directory
# and the corrupt files are moved into it along with the error log.
for f in $FILES
do
	COUNTER=$[COUNTER + 1]
	name="$(basename -- $f)"
	if gzip -t -q $f; then
		echo $name >> ${DIR}"comp_check.log"
	else
		echo $name >> ${DIR}"comp_check_error.log"
		if [ -d ${DIR}"corrupt_files" ]
		then
			:
		else
			mkdir ${DIR}"corrupt_files"
		fi
		mv $f ${DIR}"corrupt_files"
	fi
	echo "[ "$COUNTER" /"$file_count" ]"
done

# move error log into folder with corrupt files
mv ${DIR}"comp_check_error.log" ${DIR}"corrupt_files"
