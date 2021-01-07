#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-Q] [-l] [-o] file1 [file2...]

Script to convert mrxs (MIRAX) files used by 3DHistech scanners to pyramidal tiffs with vips
Requires libvips, OpenSlide & bigtiff

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-Q, --quality   Jpeg compression quality, defaults to 85
-l, --level     Slide level to convert, defaults to 0
-o, outputdir   defaults to .
--> arguments   list of .mrxs files to convert, defaults to all mrxs in path if none provided
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

setup_colors

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "${RED}$msg${NOFORMAT}"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  quality=85
  level=0
  outputdir="."
  args='*.mrxs'

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -Q | --quality)
      quality="${2-}"
      shift
      ;;
    -l | --level)
      level="${2-}"
      shift
      ;;
    -o | --outputdir)
      outputdir="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done
  args=("$@")
  [[ ${#args[@]} -eq 0 ]] && args=$( find "$script_dir" -name "*.mrxs" -maxdepth 1 )
  [[ -z ${args// } ]] && die 'No .mrxs files found in '"${script_dir}"

  # check required params and arguments
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

parse_params "$@"

# Script logic

for file in ${args[*]-}; do
    if [[ $file == *.mrxs ]]; then
    	filename="$( basename "${file%.mrxs}" )".tiff
    	outpath=${outputdir%/}/$filename
    	msg "${BLUE}Converting ${file##*/} with jpeg compression at ${quality} to ${CYAN}${filename}${NOFORMAT}"
        vips tiffsave "${file}"[level="${level}",autocrop=true] "$outpath" --tile --tile-width 256 --tile-height 256 --pyramid --bigtiff --compression=jpeg --Q "${quality}" --properties --vips-progress
     else
     	msg "${ORANGE}skipping ${file##*/}: not a .mrxs file:${NOFORMAT}"
    fi
done
