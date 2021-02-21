#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function project_secrets_detector () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  # cd --"$SELFPATH" || return $?
  local TASK="${1:-investigate}"; shift
  psd_"$TASK" "$@" || return $?
}


function vusort () { LANG=C sort --version-sort --unique; }


function psd_all_files () {
  local FIND=(
    '(' -type d -name .git -prune ')' -o
    '(' -type l -path './.vscode' ')' -o
    '(' -type d ')' -o
    -print
    )
  find "${FIND[@]}" | sed -re 's~^\./~~' | vusort
}


function psd_investigate () {
  local UNTRACKED="$(git status --porcelain | sed -nre 's~^\?\? ~~p')"
  local FILES_TODO=()
  readarray -t FILES_TODO < <(psd_all_files | grep -vxFe "${UNTRACKED:-/}")
  local FN=
  local N_CHK=0 N_OK=0 N_SUSP=0
  for FN in "${FILES_TODO[@]}"; do
    (( N_CHK += 1 ))
    if psd_investigate_one_file "$FN"; then
      (( N_OK += 1 ))
    else
      (( N_SUSP += 1 ))
    fi
  done
  echo "D: files checked: $N_CHK total, $N_OK clean, $N_SUSP suspicious" >&2
  [ "$N_CHK" -ge 1 ] || return 4$(echo "E: Found no files at all." >&2)
  [ "$N_SUSP" == 0 ] || return 4$(echo "E: Found suspicious files." >&2)
}


function psd_scan_badwords () {
  local GREP_FLAGS="${1#-}"; shift
  local CRITERIA=(
    "$SELFPATH"/crit.*
    )
  local CRIT=
  for CRIT in "${CRITERIA[@]}"; do
    if [ -x "$CRIT" -a -f "$CRIT" ]; then
      exec < <("$CRIT")
    else
      echo "W: skipped criteria file: $CRIT" >&2
    fi
  done
  grep -${GREP_FLAGS}Pe '\a[^\v]+\v?' | vusort
}


function psd_investigate_one_file () {
  local FN="$1"
  [ -e "$FN" -o -L "$FN" ] || return 3$(
    echo "W: Neither exists nor is a symlink: $FN" >&2)

  local SUSP="$(<<<$'\f<path>'"$FN" psd_scan_badwords o)"
  SUSP="${SUSP//[$'\a\v']/}"
  SUSP="${SUSP//$'\n'/, }"
  if [ -n "$SUSP" ]; then
    psd_report_file filename "$SUSP"
    return 3
  fi

  local WHY='filetype'
  if [ -L "$FN" ]; then
    SUSP="$( ( echo -n $'\f<symlink-target>'; readlink -- "$FN"
      ) | psd_scan_badwords o)"
    WHY='target'
  elif [ -f "$FN" ]; then
    SUSP="$(psd_scan_badwords no <"$FN")"
    WHY='content'
  fi
  SUSP="${SUSP//[$'\a\v']/}"
  SUSP="${SUSP//$'\n'/, }"
  if [ -n "$SUSP" ]; then
    psd_report_file "$WHY" "$SUSP"
    return 3
  fi
}


function psd_report_file () {
  local WHY="$1"; shift
  echo -n "$WHY"
  printf '\t%s' "$FN" "$@"
  echo
}


function psd_censor_pkjs () {
  local FILES=()
  readarray -t FILES < <(psd_all_files | grep -Pe '/package\.json$')
  local FN=
  for FN in "${FILES[@]}"; do
    sed -rf <(echo '
      s~(://gitlab.com/[^/]+/)[^\x22\x27 \t]+~\1??…??~g
      ') -i -- "$FN"
  done
}











project_secrets_detector "$@"; exit $?
