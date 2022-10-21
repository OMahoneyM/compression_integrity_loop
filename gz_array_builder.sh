#!bin/bash
############################################################
# Help menu                                                #
############################################################
Help(){
   # Display Help
   echo "Creates the .sou and .sh files needed to run the fastq.gz compression check script as a job array"
   echo
   echo "Syntax: $(basename "$0") [-i INPUT|-h HELP|-o OUTPUT]"
   echo "options:"
   echo "-i     [Required] INPUT directory path of fastq.gz files."
   echo "-h     Print this help."
   echo "-o     [Required] OUTPUT directory path for result logs and corrput files."
   echo
}
############################################################
############################################################
# Main program                                             #
############################################################
############################################################
# Define the arguments
while getopts ":hi:o:" option; do
   case $option in
      h|-help) # Display help menu
         Help
         exit 1;;
      i) # Enter input directory path
         DIR=${OPTARG};;
      o) # Enter output directory path
		 OUT=${OPTARG};;
     \?) # Invalid option
         echo "Error: Invalid option"
		 echo "Use -h to see valid argument options"
         exit 1;;
   esac
done

shift "$(( OPTIND - 1 ))"

# Check for required arguments
if [ -z "$DIR" ] || [ -z "$OUT" ]; then
	echo "Arguments -i and -o are required"
	echo "Please enter your directory paths for INPUT and OUTPUT"
	echo "Use -h to access the help menu" >&2
  exit 1
fi

# Check if input directory path is formatted correctly
if [[ $DIR == */ ]]; then
	:
else
	DIR=${DIR}"/"
fi

# Check if output directory path is formatted correctly
if [[ $OUT == */ ]]; then
	:
else
	OUT=${OUT}"/"
fi

# Set task ID max value
TMAX=`ls $DIR | wc -l`

# Create qsub parameters file
cat > qsub_gz_check_array.sou << EOF
qsub \
 -q sThC.q \
 -pe mthread 5 \
 -l mres=20G,h_data=4G,h_vmem=4G \
 -cwd \
 -j y \
 -N gz_check_array.job \
 -o ../logs/'gz_check_array_\$TASK_ID.log' \
 -t 1-$TMAX \
 -tc 50 \
 -b y \$PWD/gz_check.sh
EOF

# Create gzip bash file
cat > gz_check.sh << EOF
#!/bin/sh

# ----------------Commands------------------- #
echo + \`date\` job \$JOB_NAME started in \$QUEUE with jobID=\$JOB_ID on \$HOSTNAME
echo + NSLOTS = \$NSLOTS
#

# Input and output paths
DIR=$DIR
OUT=$OUT

# Check to see if list file containing the names of all the fastq.gz files
# exists. If not, create it. Is so, do nothing.
FLIST=\${OUT}"fastq_list.txt"
if [ -f "\$FLIST" ]
then
	:
else
	ls \$DIR > \${OUT}"fastq_list.txt"
fi

# This converts the SGE_TASK_ID into a useful parameter. Here it is stored in "i" and
# then passed to awk. Awk then iterates through filenames in "FLIST" and stores the
# filename in "P" which is then passed through the commands below before moving on
# to the next filename and repeating the process until all enteries have been passed
i=\$SGE_TASK_ID
P=\`awk "NR==\$i" \$FLIST\`

DIRP="\${DIR}\${P}"

# Take the filename stored in "P", pass it through the gzip command and log the results
# If file is corrupt, move it to the corrupt_files directory
if gzip -t -q \$DIRP; then
	echo \$P >> \${OUT}"gz_check.log"
else
	echo \$P >> \${OUT}"gz_check_error.log"
	if [ -d \${OUT}"corrupt_files" ]
	then
		:
	else
		mkdir \${OUT}"corrupt_files"
	fi
	mv \$DIRP \${OUT}"corrupt_files"
fi

#
echo = \`date\` job \$JOB_NAME done
EOF

# Check if files were generated
if [ -f "gz_check.sh" ] && [ -f "qsub_gz_check_array.sou" ]
then
	echo "Successfully generated job array files:"
	echo "gz_check.sh"
	echo "qsub_gz_check_array.sou"
	echo "Before using comfirm these files generated correctly"
	echo "Then launch job array using source command"
else
	echo "Job files not generated"
	echo "Use -h to access the help menu"
	exit 1
fi

# Make the resulting bash file executable
chmod +x gz_check.sh
