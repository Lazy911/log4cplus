#!/bin/bash

set -e

THIS_SCRIPT=`basename "$0"`

function usage
{
    echo "$THIS_SCRIPT <BZR_URL> <SRC_DIR>"
}

BZR_URL="$1"
if [[ -z "$BZR_URL" ]] ; then
    usage
    exit 1
fi

if [[ -z "$2" ]] ; then
    BZR_URL=${BZR_URL%/}
    BZR_BASE_URL=${BZR_URL%/*}
    BZR_BRANCH_NAME=${BZR_URL#$BZR_BASE_URL}
    BZR_BRANCH_NAME=${BZR_BRANCH_NAME#/}
    SRC_DIR=$BZR_BRANCH_NAME
else
    SRC_DIR="$2"
fi

DEST_DIR="$PWD"

TMPDIR=${TMPDIR:-${TMP:-${TEMP}}}
if [[ -z "${TMPDIR}" ]] ; then
    unset TMPDIR
else
    export TMPDIR
fi
TMP_DIR=`mktemp -d -t log4cplus.XXXXXXX`
pushd "$TMP_DIR"

TAR=${TAR:-tar}
XZ=${XZ:-xz}
BZIP2=${BZIP2:-bzip2}
GZIP=${GZIP:-gzip}
SEVENZA=${SEVENZA:-7za}
BZR=${BZR:-bzr}

$BZR export --per-file-timestamps -v "$SRC_DIR" "$BZR_URL"
$BZR version-info "$BZR_URL" >"$SRC_DIR/REVISION"

pushd "$SRC_DIR"
$SHELL ./scripts/fix-timestamps.sh
popd

$SEVENZA a -t7z "$DEST_DIR/$SRC_DIR".7z "$SRC_DIR" >/dev/null \
& $SEVENZA a -tzip "$DEST_DIR/$SRC_DIR".zip "$SRC_DIR" >/dev/null

TAR_FILE="$SRC_DIR".tar
$TAR -cvf "$TAR_FILE" "$SRC_DIR"

$XZ -e -c "$TAR_FILE" >"$DEST_DIR/$TAR_FILE".xz \
& $BZIP2 -9 -c "$TAR_FILE" >"$DEST_DIR/$TAR_FILE".bz2 \
& $GZIP -9 -c "$TAR_FILE" >"$DEST_DIR/$TAR_FILE".gz

echo waiting...
wait
echo done waiting

rm -rf "$SRC_DIR"
rm -f "$TAR_FILE"
popd
rmdir "$TMP_DIR"
