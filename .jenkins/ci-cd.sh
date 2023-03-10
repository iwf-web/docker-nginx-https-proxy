#!/bin/bash
set -e -u -o pipefail
IFS=$'\n\t'

GIT_REPO=https://github.com/iwf-web/docker-nginx-https-proxy.git
CODE_BASE=./code

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=$( cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd )

# Load Libs
scriptsCommonUtilities="$SCRIPT_DIR/../lib/bertrand-benoit/scripts-common/utilities.sh"
[[ ! -f "$scriptsCommonUtilities" ]] && echo -e "ERROR: scripts-common utilities not found, you must initialize your git submodule once after you cloned the repository:\ngit submodule init\ngit submodule update" >&2 && exit 1
# shellcheck disable=1090
. "$scriptsCommonUtilities"

[[ -t 1 ]] && SH_PIPED=true || SH_PIPED=false # detect if output is piped
if [[ $SH_PIPED == true ]]; then
  TEXT_RESET=$(tput sgr0)
  TEXT_ERROR=$(tput setaf 160)
  TEXT_INFO=$(tput setaf 2)
  TEXT_WARN=$(tput setaf 214)
  TEXT_BOLD=$(tput bold)
  TEXT_ITALIC=$(tput sitm || true) # not supported on MacOS
  TEXT_UNDERLINE=$(tput smul)
else
  TEXT_RESET=""
  TEXT_ERROR=""
  TEXT_INFO=""
  TEXT_WARN=""
  TEXT_BOLD=""
  TEXT_ITALIC=""
  TEXT_UNDERLINE=""
fi

[[ $(echo -e '\xe2\x82\xac') == '€' ]] && SH_UNICODE=true || SH_UNICODE=false # detect if unicode is supported
if [[ $SH_UNICODE == true ]]; then
  ICON_SUCCESS="✅"
  ICON_FAIL="⛔"
  ICON_ALERT="✴️"
  ICON_WAIT="⏳"
  ICON_INFO="🌼"
  ICON_CONFIG="🌱"
  ICON_CLEAN="🧽"
  ICON_REQUIRE="🔌"
else
  ICON_SUCCESS="OK "
  ICON_FAIL="!! "
  ICON_ALERT="?? "
  ICON_WAIT="..."
  ICON_INFO="(i)"
  ICON_CONFIG="[c]"
  ICON_CLEAN="[c]"
  ICON_REQUIRE="[r]"
fi

# Check required tools
checkBin docker || errorMessage "${ICON_REQUIRE}${TEXT_ERROR} This tool requires Docker. Install it please, and then run this tool again.${TEXT_RESET}"

usage() {
  echo "CI/CD script for Jenkins to build and upload docker image.

Usage:
  $0 -b <name>
  $0 --branch <name> --push
  $0 --branch <name> --verbose
  $0 -h | --help

Options:
  -h --help                Show this screen.
  -v --verbose             Verbose mode [default: false].
  -b --branch <x>          Branch to clone and build docker image with.
  -p --push --pushregistry Whether to push to Docker Hub (if build succeeded) [default: false].
  -n --builder <x>         Docker builder to use [default: builder-default]."
}

FLAGS_GETOPT_CMD="getopt"
if [[ "$(uname -s)" == "Darwin" ]]; then
  # Overwrite this when running on MacOS
  checkPath "$(brew --prefix gnu-getopt)/bin/getopt" && FLAGS_GETOPT_CMD="$(brew --prefix gnu-getopt)/bin/getopt"
fi
set +e
OPTS=$( $FLAGS_GETOPT_CMD --options hvb:pn: --longoptions help,verbose,branch:,push,pushregistry,builder: --name "$0" -- "$@" )
if (( $? != 0 )); then errorMessage "${ICON_FAIL}${TEXT_ERROR} Incorrect options provided ... exiting.${TEXT_RESET}"; fi
set -e
eval set -- "$OPTS"

PUSH=false
BUILDER=builder-default
while true; do
  case "$1" in
    -h | --help )
      usage
      exit 0
      ;;
    -v | --verbose )
      # shellcheck disable=2034
      BSC_VERBOSE=1
      ;;
    -b | --branch )
      GIT_BRANCH=$2
      shift
      ;;
    -p | --push | --pushregistry )
      PUSH=true
      ;;
    -n | --builder )
      BUILDER=$2
      shift
      ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    -- ) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    * ) writeMessage "${ICON_FAIL}${TEXT_ERROR} Unexpected option: $1 - this should not happen.${TEXT_RESET}"; usage; exit 2 ;;
  esac
  shift
done

info "${ICON_INFO} Script directory:   \"${SCRIPT_DIR}\""
info "${ICON_INFO} Project directory:  \"${PROJECT_DIR}\""
info "${ICON_INFO} Code base:          \"${CODE_BASE}\""

info "${ICON_INFO} Git branch:         \"${GIT_BRANCH:-}\""
info "${ICON_INFO} Git repository:     \"${GIT_REPO}\""

info "${ICON_INFO} Docker builder:     \"${BUILDER}\""
info "${ICON_INFO} Push to Docker Hub: \"${PUSH}\""

# Git branch is mandatory
if [[ -z ${GIT_BRANCH:-} ]]; then
  usage
  exit 1
fi

# Check if Docker Daemon is running
if ! curl -s --unix-socket /var/run/docker.sock http/_ping 2>&1 >/dev/null; then
  errorMessage "${ICON_FAIL}${TEXT_ERROR} Docker is not running, please start it first.${TEXT_RESET}"
fi

# Retrieve code from git
if [[ -d ${CODE_BASE} ]]; then rm -rf ${CODE_BASE}; fi
mkdir ${CODE_BASE}
git clone --depth 1 -b "${GIT_BRANCH}" ${GIT_REPO} ${CODE_BASE}
cd ./code

GIT_REVISION_COUNT=$(git log --oneline | wc -l | tr -d ' ')
#GIT_PROJECT_VERSION=$(git describe --tags --long)
GIT_PROJECT_VERSION=$(git describe --abbrev=0 --tags --exact-match)
GIT_CLEAN_VERSION=${GIT_PROJECT_VERSION%%-*}
#writeMessage "Full build: $GIT_PROJECT_VERSION-$GIT_REVISION_COUNT"
GIT_BRANCH=$(git name-rev --name-only HEAD | sed "s/\^.*//")
GIT_COMMIT=$(git rev-parse HEAD)
GIT_COMMIT_SHORT=$(git rev-parse --short HEAD)
GIT_DIRTY=false
GIT_BUILD_CREATOR=$(git config user.email)

CURRENT_DATETIME=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

if [ -n "${GIT_PROJECT_VERSION}" ]; then
  BUILD_NUMBER=${GIT_PROJECT_VERSION}
  DOCKER_TAG=latest
else
  BUILD_NUMBER=sha-${GIT_COMMIT_SHORT}
  DOCKER_TAG=latest
fi
#DOCKER_BASE_DIGEST=$(docker images --digests iwfwebsolutions/nginx:1.22-latest --format '{{.Digest}}' | sed s/^\<none\>//)
DOCKER_BASE_DIGEST=$(docker manifest inspect iwfwebsolutions/nginx:1.22-latest -v | jq -r '.Descriptor.digest')
DOCKER_IMAGE=iwfwebsolutions/nginx-https-proxy

# Whether the repo has uncommitted changes
if [[ $(git status -s) ]]; then
    GIT_DIRTY=true
fi

writeMessage "Building docker image '${DOCKER_IMAGE}' with build '$BUILD_NUMBER' ($DOCKER_TAG) ..."

# TODO: Somehow check if installing emulators is needed
docker run --privileged --rm tonistiigi/binfmt --install all &>/dev/null

# Check if Buildx builder already exists and create if not
if ! docker buildx ls | grep "${BUILDER}" &>/dev/null; then
  docker buildx create --name "${BUILDER}" --driver docker-container --bootstrap --use
fi

cd "$PROJECT_DIR/src/" || errorMessage "Cannot cd to src folder"
# shellcheck disable=2097,2098
REPO=${DOCKER_IMAGE} \
GIT_BRANCH="${GIT_BRANCH}" \
GIT_COMMIT="${GIT_COMMIT}" \
GIT_DIRTY="${GIT_DIRTY}" \
GIT_BUILD_CREATOR="${GIT_BUILD_CREATOR}" \
BUILD_NUMBER="${BUILD_NUMBER}" \
LABEL_CREATED="${CURRENT_DATETIME}" \
LABEL_VERSION="${GIT_BRANCH}" \
LABEL_REVISION="${GIT_COMMIT}" \
LABEL_BASE_DIGEST="${DOCKER_BASE_DIGEST}" \
TAG="${DOCKER_TAG}" \
TAG2="${BUILD_NUMBER}" \
docker buildx bake build $( [[ "$PUSH" == true ]] && printf %s '--push' )

if (( $? == 0 )); then
  writeMessage "${ICON_SUCCESS}${TEXT_INFO} Done${TEXT_RESET}"
else
  errorMessage "${ICON_FAIL}${TEXT_ERROR} Build failed${TEXT_RESET}"
fi

if [[ -d ${CODE_BASE} ]]; then rm -rf ${CODE_BASE}; fi
