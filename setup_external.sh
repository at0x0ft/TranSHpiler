#!/usr/bin/env sh
set -eu

setup_external() {
  # ref: https://github.com/ko1nksm/readlinkf/blob/master/readlinkf.sh
  readlinkf() {
    [ "${1:-}" ] || return 1
    max_symlinks=40
    CDPATH='' # to avoid changing to an unexpected directory

    target=$1
    [ -e "${target%/}" ] || target=${1%"${1##*[!/]}"} # trim trailing slashes
    [ -d "${target:-/}" ] && target="$target/"

    cd -P . 2>/dev/null || return 1
    while [ "$max_symlinks" -ge 0 ] && max_symlinks=$((max_symlinks - 1)); do
      if [ ! "$target" = "${target%/*}" ]; then
        case $target in
          /*) cd -P "${target%/*}/" 2>/dev/null || break ;;
          *) cd -P "./${target%/*}" 2>/dev/null || break ;;
        esac
        target=${target##*/}
      fi

      if [ ! -L "$target" ]; then
        target="${PWD%/}${target:+/}${target}"
        printf '%s\n' "${target:-/}"
        return 0
      fi

      # `ls -dl` format: "%s %u %s %s %u %s %s -> %s\n",
      #   <file mode>, <number of links>, <owner name>, <group name>,
      #   <size>, <date and time>, <pathname of link>, <contents of link>
      # https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ls.html
      link=$(ls -dl -- "$target" 2>/dev/null) || break
      target=${link#*" $target -> "}
    done
    return 1
  }
  local readonly SCRIPT_PATH=$(readlinkf "${0}")
  local readonly SCRIPT_ROOT=$(dirname -- "${SCRIPT_PATH}")
  local readonly REPOSITORY_ROOT="${SCRIPT_ROOT}"
  local readonly EXTERNAL_MODULES_PATH="${SCRIPT_ROOT}/external"
  local readonly EXTERNAL_CONFIG_DIRPATH="${EXTERNAL_MODULES_PATH}/config"
  local readonly MODULES_LIST_PATH="${EXTERNAL_CONFIG_DIRPATH}/modules"
  local readonly GIT_SPARSE_CHECKOUT_CONFIG_SOURCE_DIRPATH="${EXTERNAL_CONFIG_DIRPATH}/sparse_checkout"

  get_relative_path() {
    local readonly from="${1}"
    local readonly to="${2}"
    printf '%s' "${to##${from}/}"
    return 0
  }

  get_git_submodule_path() {
    local readonly submodule_name="${1}"
    printf '%s/.git/modules/%s/%s' "${REPOSITORY_ROOT}" $(get_relative_path "${SCRIPT_ROOT}" "${EXTERNAL_MODULES_PATH}") "${submodule_name}"
    return 0
  }

  get_git_sparse_checkout_config_destination_path() {
    local readonly submodule_name="${1}"
    printf '%s/info/sparse-checkout' $(get_git_submodule_path "${submodule_name}")
    return 0
  }

  cd "${REPOSITORY_ROOT}"
  git submodule update --init --recursive
  for line in $(cat "${MODULES_LIST_PATH}"); do
    local readonly submodule_name="${line%%,*}"
    local readonly submodule_url="${line##*,}"

    local readonly git_submodule_path=$(get_git_submodule_path "${submodule_name}")
    local readonly submodule_destination_path="${EXTERNAL_MODULES_PATH}/${submodule_name}"

    if [ ! -d "${git_submodule_path}" ]; then
      git submodule add "${submodule_url}" $(get_relative_path "${REPOSITORY_ROOT}" "${submodule_destination_path}")
    fi

    git -C "${submodule_destination_path}" config core.sparsecheckout true

    local readonly git_sparse_checkout_config_source_path="${GIT_SPARSE_CHECKOUT_CONFIG_SOURCE_DIRPATH}/${submodule_name}"
    if [ -f "${git_sparse_checkout_config_source_path}" ]; then
      local readonly git_sparse_checkout_config_destination_path=$(get_git_sparse_checkout_config_destination_path "${submodule_name}")
      cp "${git_sparse_checkout_config_source_path}" "${git_sparse_checkout_config_destination_path}"
      git -C "${submodule_destination_path}" read-tree -mu HEAD
    fi
  done

  return 0
}
setup_external
