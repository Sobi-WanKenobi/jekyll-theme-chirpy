#!/usr/bin/env bash
#
# Init the evrionment for new user.

set -eu

ACTIONS_WORKFLOW=pages-deploy.yml

TEMP_SUFFIX="to-delete" #  temporary file suffixes that make `sed -i` compatible with BSD and Linux

help() {
  echo "Usage:"
  echo
  echo "   bash /path/to/init [options]"
  echo
  echo "Options:"
  echo "     --no-gh              Do not deploy to Github."
  echo "     -h, --help           Print this help information."
}

check_status() {
  if [[ -n $(git status . -s) ]]; then
    echo "Error: Commit unstaged files first, and then run this tool again."
    exit -1
  fi
}

check_init() {
  local _has_inited=false

  if [[ ! -d .github ]]; then # using option `--no-gh`
    _has_inited=true
  else
    if [[ -f .github/workflows/$ACTIONS_WORKFLOW ]]; then
      # on BSD, the `wc` could contains blank
      local _count="$(find .github/workflows/ -type f -name "*.yml" | wc -l)"
      if [[ ${_count//[[:blank:]]/} == 1 ]]; then
        _has_inited=true
      fi
    fi
  fi

  if $_has_inited; then
    echo "Already initialized."
    exit 0
  fi
}

checkout_latest_tag() {
  tag=$(git describe --tags $(git rev-list --tags --max-count=1))
  git reset --hard "$tag"
}

init_files() {
  if $_no_gh; then
    rm -rf .github
  else
    ## Change the files of `.github`
    mv .github/workflows/$ACTIONS_WORKFLOW.hook .
    rm -rf .github
    mkdir -p .github/workflows
    mv ./${ACTIONS_WORKFLOW}.hook .github/workflows/${ACTIONS_WORKFLOW}

    ## Cleanup image settings in site config
    sed -i.$TEMP_SUFFIX "s/^img_cdn:.*/img_cdn:/;s/^avatar:.*/avatar:/" _config.yml
    rm -f _config.yml.$TEMP_SUFFIX
  fi

  # trace the gem lockfile on user-end
  sed -i.$TEMP_SUFFIX "/Gemfile.lock/d" .gitignore
  rm -f ".gitignore.$TEMP_SUFFIX"

  # remove the other fies
  rm -rf _posts/*

  # save changes
  git add -A
  git commit -m "chore: initialize the environment" -q

  echo "[INFO] Initialization successful!"
}

check_status

check_init

_no_gh=false

while (($#)); do
  opt="$1"
  case $opt in
  --no-gh)
    _no_gh=true
    shift
    ;;
  -h | --help)
    help
    exit 0
    ;;
  *)
    # unknown option
    help
    exit 1
    ;;
  esac
done

checkout_latest_tag

init_files
