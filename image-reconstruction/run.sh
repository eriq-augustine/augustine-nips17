#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/scripts/fetchData.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/requirements.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/psl.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && source "${THIS_DIR}/../scripts/tuffy.sh"
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function run() {
   local outBaseDir="${THIS_DIR}/out"
   local datasets='caltech olivetti'

   for dataset in $datasets; do
      psl::runLearn \
         "${outBaseDir}/psl/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} learn" \
         '' \
         "${PSL_JAR_PATH}"

      psl::runEval \
         "${outBaseDir}/psl/${dataset}" \
         'image-reconstruction' \
         "${THIS_DIR}/psl-cli" \
         "${THIS_DIR}/scripts" \
         "${dataset} eval" \
         "${outBaseDir}/psl/${dataset}/${LEARNED_PSL_MODEL_FILENAME}" \
         '-ec' \
         "${PSL_JAR_PATH}"

      tuffy::runLearn \
         "${outBaseDir}/tuffy/${dataset}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/processed/${dataset}/eval"

      tuffy::runEval \
         "${outBaseDir}/tuffy/${dataset}" \
         "${THIS_DIR}/mln" \
         "${THIS_DIR}/scripts" \
         "${THIS_DIR}/data/processed/${dataset}/eval" \
         "${outBaseDir}/tuffy/${dataset}/${LEARNED_MLN_MODEL_FILENAME}"
   done
}

function main() {
   trap exit SIGINT

   requirements::check_requirements
   requirements::fetch_all_jars
   fetchData::main
   run
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
