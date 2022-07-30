#!/bin/bash

defaultPipeline="pipeline.json"
defaultBuildConfiguration=""
defaultBranchName="main"
defaultPoolForChanges="yes"
defaultSaveChanges="y"
newJsonFileName="pipeline-$(date +"%Y-%m-%d").json"


checkJQ() {
  # jq test
  type jq >/dev/null 2>&1
  exitCode=$?

  if [ "$exitCode" -ne 0 ]; then
    printf "    'jq' not found! (json parser)\n"
    printf "    MacOS Installation:  https://jira.amway.com:8444/display/CLOUD/Configure+PowerShell+for+AWS+Automation#ConfigurePowerShellforAWSAutomation-MacOSSetupforBashScript\n"
    printf "    Ubuntu Installation: sudo apt install jq\n"
    printf "    Redhat Installation: sudo yum install jq\n"
    exit 1
  fi
}

# perform checks:
checkJQ

NUMBER_OF_PARAMS=$#
HAS_Branch=$(jq '.pipeline.stages[0].actions[0].configuration | has ("Branch")' "$defaultPipeline")

HAS_Owner=$(jq '.pipeline.stages[0].actions[0].configuration | has ("Owner")' "$defaultPipeline")

HAS_Repo=$(jq '.pipeline.stages[0].actions[0].configuration | has ("Repo")' "$defaultPipeline")

HAS_PollForSourceChanges=$(jq '.pipeline.stages[0].actions[0].configuration | has ("PollForSourceChanges")' "$defaultPipeline")

HAS_version=$(jq '.pipeline | has ("version")' "$defaultPipeline")

if [[ $HAS_Branch && $HAS_Owner && $HAS_Repo && $HAS_PollForSourceChanges && $HAS_version ]]; then
  true
else
  printf "Some properties is missing in JSON file"
  exit 1
fi

pipelineName=$1
if [[ $NUMBER_OF_PARAMS -eq 1 ]]; then
  if [[ -f "$pipelineName" ]]; then
    echo "$pipelineName exists."
  else
    printf "File path wrong or file does not exists"
  fi
fi

if [[ $NUMBER_OF_PARAMS -eq 9 ]]; then
shift
optspec=":hv-:"

while getopts "$optspec" optchar; do
  case "${optchar}" in
  -)
    case "${OPTARG}" in
    configuration)
      val="${!OPTIND}"
      echo "val: $val"
      buildConfiguration=$val
      OPTIND=$(($OPTIND + 1))
      ;;
    owner)
      val="${!OPTIND}"
      OPTIND=$(($OPTIND + 1))
      owner=$val
      echo "Parsing dir 1.1: '--${OPTARG}', value: '${val}'" >&2
      ;;
    branch)
      val="${!OPTIND}"
      OPTIND=$(($OPTIND + 1))
      branchName=$val
      echo "Parsing dir 1.1: '--${OPTARG}', value: '${val}'" >&2
      ;;
    poll-for-source-changes)
      val="${!OPTIND}"
      OPTIND=$(($OPTIND + 1))
      poolChange=$val
      echo "Parsing dir 1.1: '--${OPTARG}', value: '${val}'" >&2
      ;;
    *)
      if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
        echo "Unknown option 3 --${OPTARG}" >&2
      fi
      ;;
    esac
    ;;
  *)
    if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
      echo "Non-option argument 6: '-${OPTARG}'" >&2
    fi
    ;;
  esac
done

fi


if [[ $NUMBER_OF_PARAMS -eq 0 ]]; then
  echo -n "Please, enter the pipeline's definitions file path (default: $defaultPipeline): "
  read -r pipelineName
  pipelineName=${pipelineName:-$defaultPipeline}

  echo -n "Which BUILD_CONFIGURATION name are you going to use (default: $defaultBuildConfiguration): "
  read -r buildConfiguration
  buildConfiguration=${buildConfiguration:-$defaultBuildConfiguration}

  echo -n "Enter a GitHub owner/account: "
  read -r owner

  echo -n "Enter a GitHub repository name: "
  read -r repName

  echo -n "Enter a GitHub branch name (default: $defaultBranchName):"
  read -r branchName
  branchName=${branchName:-$defaultBranchName}

  echo -n "Do you want the pipeline to poll for changes (yes/no) (default: $defaultPoolForChanges)?:"
  read -r poolChange
  poolChange=${poolChange:-$defaultPoolForChanges}

  echo -n "Do you want to save changes (y/n) (default: $defaultSaveChanges)?:"
  read -r saveChange
  saveChange=${saveChange:-$defaultSaveChanges}
fi

VER=$(jq '.pipeline.version' $pipelineName)

NEW_VERSION=$((VER + 1))

CONFIG=$(jq -n --arg buildConfiguration "$buildConfiguration" '{"name": "BUILD_CONFIGURATION", "value": $buildConfiguration, "type":"PLAINTEXT"}')


if [ "$saveChange" = "n" ]; then
  echo "The ${pipelineName} pipeline update has been terminated."
  exit 0
elif [ $NUMBER_OF_PARAMS -eq 9 ] || [ "$saveChange" = "y" ]; then
  echo "Pipeline update has started"
  jq --arg branchName "$branchName" --arg owner "$owner" --arg repName "$repName" --arg pollChanges "$defaultPoolForChanges" --arg version "$NEW_VERSION" 'del(.metadata) | .pipeline.stages[0].actions[0].configuration.Branch = $branchName | .pipeline.stages[0].actions[0].configuration.Owner = $owner | .pipeline.stages[0].actions[0].configuration.Repo = $repName | .pipeline.stages[0].actions[0].configuration.PollForSourceChanges = $pollChanges | .pipeline.version = $version ' "$pipelineName" >"$newJsonFileName"

  jq --arg CONFIG "$CONFIG" '(.pipeline.stages[] | .actions[]? .configuration?.EnvironmentVariables) |= ($CONFIG| tostring)' "$newJsonFileName" >newJson.json

fi

exit 0
