#!/bin/bash

trap exit SIGINT

DATA_DIR='data'
FETCH_DATA_SCRIPT="fetchData.sh"
JAR_PATH='../psl-cli-CANARY.jar'
JAR_URL='https://linqs-data.soe.ucsc.edu/maven/repositories/psl-releases/org/linqs/psl-cli/CANARY/psl-cli-CANARY.jar'

FETCH_COMMAND=''

function err() {
   echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

# Check for:
#  - wget or curl (final choice to be set in FETCH_COMMAND)
#  - tar
#  - java
function check_requirements() {
   local hasWget

   type wget > /dev/null 2> /dev/null
   hasWget=$?

   type curl > /dev/null 2> /dev/null
   if [[ "$?" -eq 0 ]]; then
      FETCH_COMMAND="curl -o"
   elif [[ "${hasWget}" -eq 0 ]]; then
      FETCH_COMMAND="wget -O"
   else
      err 'wget or curl required to download dataset'
      exit 10
   fi

   type tar > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'tar required to extract dataset'
      exit 11
   fi

   type ruby > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'ruby required to generate psl files'
      exit 12
   fi

   type java > /dev/null 2> /dev/null
   if [[ "$?" -ne 0 ]]; then
      err 'java required to run project'
      exit 13
   fi
}

function fetch_data() {
   pushd . > /dev/null
   cd $DATA_DIR

   bash $FETCH_DATA_SCRIPT
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to download dataset'
      exit 20
   fi

   popd > /dev/null
}

function fetch_jar() {
   if [[ -e "${JAR_PATH}" ]]; then
      echo "PSL jar found cached, skipping download."
      return
   fi

   echo "Downloading the jar with command: $FETCH_COMMAND"
   $FETCH_COMMAND "${JAR_PATH}" "${JAR_URL}"
   if [[ "$?" -ne 0 ]]; then
      err 'Failed to download jar'
      exit 30
   fi
}

function run() {
   BASE_DIR=`pwd`
   SCRIPTS_DIR="${BASE_DIR}/scripts"
   GENERATE_DATAFILE_SCRIPT="${SCRIPTS_DIR}/generateDataFiles.rb"

   OUT_BASE_DIR="${BASE_DIR}/out"

   FOLDS='22050 33075 38588 44100 49613 55125 66150'

   PSL_CLI_DIR="${BASE_DIR}/psl-cli"
   MODEL_PATH="${PSL_CLI_DIR}/party-affiliation.psl"
   DATA_TEMPLATE_PATH="${PSL_CLI_DIR}/party-affiliation-template.data"

   for fold in $FOLDS; do
      outDir="${OUT_BASE_DIR}/${fold}"
      mkdir -p $outDir

      outputEvalPath="${outDir}/out-eval.txt"
      evalDataFilePath="${outDir}/${fold}-eval.data"

      echo "Generating eval data file to ${evalDataFilePath}."
      ruby $GENERATE_DATAFILE_SCRIPT $DATA_TEMPLATE_PATH $evalDataFilePath $fold $METHOD_EVAL

      echo "Running ${fold} (eval). Output redirected to ${outputEvalPath}."
      time java -jar $JAR_PATH -i -d ${evalDataFilePath} -m ${MODEL_PATH} -D log4j.threshold=DEBUG -o ${outDir} > ${outputEvalPath}
   done
}

function main() {
   check_requirements
   fetch_data
   fetch_jar
   run
}

main "$@"
