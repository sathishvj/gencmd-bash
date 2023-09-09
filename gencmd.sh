#!/bin/bash
# generate cmd line commands with MakerSuite/Palm/Google Cloud

function usage {
        echo "Usage: $(basename $0) [-h] [-l NUMBER] [-o OS]" 2>&1
        echo 'Generate a cmd:'
        echo '   -o OS       Operating system for the cmd. Default is unix.'
        echo '   -n NUMBER   Number of suggestions you want to see. Default is 4.'
        echo '   -t TEMP     Temperature [0 to 1.0]. Default is 0.5.'
        echo '   -v 	     Verbose. Shows JSON and curl output. Default is off.'
        echo '   -l 	     Line numbers in output. Default is off.'
        echo '   -e 	     Show a few examples.'
        echo '   -h          Help with usage.'
		echo ''
		echo 'Written by Sathish VJ'
        exit 1
}

function examples {
        echo "Ex: bash $(basename $0) convert the first 10 seconds of an mp4 video into a gif" 2>&1
        echo "Ex: bash $(basename $0) find files that contain the text html" 2>&1
        echo "Ex: bash $(basename $0) find files that has extension pdf" 2>&1
		exit 0
}

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed. Please install jq.' >&2
  exit 1
fi

# if no input argument found, exit the script with usage
if [[ ${#} -eq 0 ]]; then
   usage
fi

# Set default values
OS="unix"
NUMBER=4
TEMP=0.5
VERBOSE=0
LINES=0

# Define list of arguments expected in the input
#optstring=":onh:"
optstring=":o:n:t:vlhe"

while getopts ${optstring} arg; do
  case ${arg} in
    o)
      OS="${OPTARG}"
      ;;
    n)
      NUMBER=${OPTARG}
      ;;
    t)
      TEMP=${OPTARG}
      ;;
    v)
      VERBOSE=1
      ;;
    l)
      LINES=1
      ;;
    h)
      usage
      ;;
    e)
      examples
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      echo
      usage
      ;;
  esac
done


if [ -z "$MAKERSUITE_API_KEY" ]; then
	echo "MAKERSUITE_API_KEY is empty. Do 'export MAKERSUITE_API_KEY=<key you got from Maker Suite for your project.>'"
	exit 2
fi

#echo "Before shift:"
#echo "number=$NUMBER"
#echo "os=$OS"
#echo "others=$@"
#echo "VERBOSE=$VERBOSE"
#exit 0

shift "$(( OPTIND-1 ))"

#echo "After shift:"
#echo "number=$NUMBER"
#echo "os=$OS"
#echo "others=$@"
#echo "VERBOSE=$VERBOSE"
#exit 0


prompt="You are very good at generating the $OS command line commands and options to accomplish a given task. Given a description of what the user wants to get done, you should generate the appropriate command line options. The description of the task is: $@"
#echo "prompt=$prompt"
d="{ 'prompt': { 'text': '$prompt'}, 'temperature': $TEMP, 'top_k': 40, 'top_p': 0.95, 'candidate_count': ${NUMBER}, 'max_output_tokens': 1024, 'stop_sequences': [], 'safety_settings': [{'category':'HARM_CATEGORY_DEROGATORY','threshold':1},{'category':'HARM_CATEGORY_TOXICITY','threshold':1},{'category':'HARM_CATEGORY_VIOLENCE','threshold':2},{'category':'HARM_CATEGORY_SEXUAL','threshold':2},{'category':'HARM_CATEGORY_MEDICAL','threshold':2},{'category':'HARM_CATEGORY_DANGEROUS','threshold':2}]}"
#echo "d=$d"

SILENT_OPTION="--silent"
if [ $VERBOSE -eq 1 ]; then
	SILENT_OPTION=""
fi

output=$(curl $SILENT_OPTION \
  -H 'Content-Type: application/json' \
  -X POST 'https://generativelanguage.googleapis.com/v1beta2/models/text-bison-001:generateText?key='${MAKERSUITE_API_KEY} \
  -d "${d}") 

if [ $VERBOSE -eq 1 ]; then
	echo $output | jq
echo
fi

i=1
echo $output | jq -c '.candidates[].output' | while read object; do
	object=${object/\"\`\`\`n/}
	object=${object/n\`\`\`\"/}
	if [ $LINES -eq 1 ]; then
		echo "$i: $object"
		i=$((i+1))
	else
		echo "$object"
	fi
done
