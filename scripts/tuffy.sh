#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LEARNED_MLN_MODEL_FILENAME='learned-model.mln'

function tuffy::runLearn() {
   local outDir=$1
   local cliDir=$2
   local scriptsDir=$3
   local sourceDataDir=$4

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateMLNData.rb"
   local programPath="${cliDir}/prog.mln"
   local queryPath="${cliDir}/query.db"
   local evidencePath="${outDir}/evidence.db"
   local resultsLearnPath="${outDir}/${LEARNED_MLN_MODEL_FILENAME}"
   local outputLearnPath="${outDir}/out-learn.txt"

   echo "Generating Tuffy (learn) data file to ${evidencePath}."
   ruby "${generateDataScript}" "${sourceDataDir}" "${evidencePath}" 'learn'

   echo "Running Tuffy (learn). Output redirected to ${outputLearnPath}."
   time `requirements::java` -jar "${TUFFY_JAR_PATH}" -learnwt -dMaxIter 25 -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsLearnPath}" -marginal > ${outputLearnPath}

   rm -f "${evidencePath}"
}

function tuffy::runEval() {
   local outDir=$1
   local cliDir=$2
   local scriptsDir=$3
   local sourceDataDir=$4
   local programPath=$5

   mkdir -p $outDir

   local generateDataScript="${scriptsDir}/generateMLNData.rb"
   local queryPath="${cliDir}/query.db"
   local evidencePath="${outDir}/evidence.db"
   local outputEvalPath="${outDir}/out-eval.txt"
   local resultsEvalPath="${outDir}/results.txt"

   echo "Generating Tuffy (eval) data file to ${evidencePath}."
   ruby "${generateDataScript}" "${sourceDataDir}" "${evidencePath}" 'eval'

   echo "Running Tuffy (eval). Output redirected to ${outputEvalPath}."
   time java -jar "${TUFFY_JAR_PATH}" -conf "${TUFFY_CONFIG_PATH}" -i "${programPath}" -e "${evidencePath}" -queryFile "${queryPath}" -r "${resultsEvalPath}" -marginal > ${outputEvalPath}

   rm -f "${evidencePath}"
}
