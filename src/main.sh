#!/bin/bash

function parseInputs {
  # Required inputs
  if [ "${INPUT_PROMTOOL_ACTIONS_FILES}" != "" ]; then
    promFiles=${INPUT_PROMTOOL_ACTIONS_FILES}
  else
    echo "Input promtool_files cannot be empty"
    exit 1
  fi

  if [ "${INPUT_PROMTOOL_ACTIONS_SUBCOMMAND}" != "" ]; then
    promtoolSubcommand=${INPUT_PROMTOOL_ACTIONS_SUBCOMMAND}
  else
    echo "Input promtool_subcommand cannot be empty"
    exit 1
  fi

  # Optional inputs
  promtoolVersion="latest"
  if [ "${INPUT_PROMTOOL_ACTIONS_VERSION}" != "" ] || [ "${INPUT_PROMTOOL_ACTIONS_VERSION}" != "latest" ]; then
    promtoolVersion=${INPUT_PROMTOOL_ACTIONS_VERSION}
  fi

  amtoolVersion="latest"
  if [ "${INPUT_AMTOOL_ACTIONS_VERSION}" != "" ] || [ "${INPUT_AMTOOL_ACTIONS_VERSION}" != "latest" ]; then
    amtoolVersion=${INPUT_AMTOOL_ACTIONS_VERSION}
  fi

  promtoolComment=0
  if [ "${INPUT_PROMTOOL_ACTIONS_COMMENT}" == "1" ] || [ "${INPUT_PROMTOOL_ACTIONS_COMMENT}" == "true" ]; then
    promtoolComment=1
  fi
}


function installTool () {
  if [[ "$3" == "latest" ]]; then
    echo "Checking the latest version of $1"
    promtoolVersion=$(git ls-remote --tags --refs --sort="v:refname"  https://github.com/prometheus/$2 | grep -v '[-].*' | tail -n1 | sed 's/.*\///' | cut -c 2-)
    if [[ -z "$3" ]]; then
      echo "Failed to fetch the latest version"
      exit 1
    fi
  fi
  
  url="https://github.com/prometheus/$2/releases/download/v$3/prometheus-$3.linux-amd64.tar.gz"

  echo "Downloading $1 v$3"
  curl -s -S -L -o /tmp/$1_$3 ${url}
  if [ "${?}" -ne 0 ]; then
    echo "Failed to download $1 v$3"
    exit 1
  fi
  echo "Successfully downloaded $1 v$3"

  echo "Unzipping $1 v$3"
  tar -zxf /tmp/$1_$3 --strip-components=1 --directory /usr/local/bin &> /dev/null
  if [ "${?}" -ne 0 ]; then
    echo "Failed to unzip $1 v$3"
    exit 1
  fi
  echo "Successfully unzipped $1 v$3"
}

function main {
  # Source the other files to gain access to their functions
  scriptDir=$(dirname ${0})
  source ${scriptDir}/promtool_check_rules.sh
  source ${scriptDir}/promtool_check_config.sh
  source ${scriptDir}/amtool_check_config.sh

  parseInputs
  cd ${GITHUB_WORKSPACE}

  case "${promtoolSubcommand}" in
    config)
      installTool "promtool" "prometheus" "$promtoolVersion"
      promtoolCheckConfig ${*}
      ;;
    rules)
      installTool "promtool" "prometheus" "$promtoolVersion"
      promtoolCheckRules ${*}
      ;;
    alertmanager)
      installTool "amtool" "alertmanager" "$amtoolVersion"
      amtoolCheckRules ${*}
      ;;
    *)
      echo "Error: Must provide a valid value for promtool_subcommand"
      exit 1
      ;;
  esac
}

main "${*}"
