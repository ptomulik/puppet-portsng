#! /bin/sh

# Build puppet module in /tmp for a given commit or tag.

set -e

ROOT=$(readlink -f "$(dirname $0)/..")
SOURCE="."
TARGET=`mktemp -d`

function do_build_module {
  tag=$1
  tgz="$TARGET/ptomulik-portsng-${tag}.tar.gz"
  dir="ptomulik-portsng-$tag/"
  git archive --prefix $dir --output $tgz $tag
  (cd $TARGET && tar -xzf $tgz && cd $TARGET/$dir && puppet module build)
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <commit>" >&2;
  echo "   or: $0 <tag>" >&2;
  exit 1
fi

(cd $ROOT && do_build_module $1)
