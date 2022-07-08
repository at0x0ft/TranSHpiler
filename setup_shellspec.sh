#!/usr/bin/env sh
set -eux

setup_shellspec() {
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
  local readonly SHELLSPEC_DESTINATION_PATH='shellspec'
  # TODO: consider ssh cloning pattern.
  local readonly SHELLSPEC_GIT_REPOSITORY_HTTP_URL='https://github.com/shellspec/shellspec.git'
  local readonly SHELLSPEC_SPARSE_CHECKOUT_CONFIG_SOURCE_PATH="${REPOSITORY_ROOT}/etc/git/sparse_checkout/shellspec"
  local readonly SHELLSPEC_SPARSE_CHECKOUT_CONFIG_DESTINATION_PATH="${REPOSITORY_ROOT}/.git/modules/shellspec/info/sparse-checkout"

  cd "${REPOSITORY_ROOT}"
  git submodule add "${SHELLSPEC_GIT_REPOSITORY_HTTP_URL}" "${SHELLSPEC_DESTINATION_PATH}"
  git -C "${SHELLSPEC_DESTINATION_PATH}" config core.sparsecheckout true
  cp "${SHELLSPEC_SPARSE_CHECKOUT_CONFIG_SOURCE_PATH}" "${SHELLSPEC_SPARSE_CHECKOUT_CONFIG_DESTINATION_PATH}"
  git -C "${SHELLSPEC_DESTINATION_PATH}" read-tree -mu HEAD

  return 0
}
setup_shellspec
