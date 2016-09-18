#!/bin/sh

set -e

# Fix for hanging "script -qa ... " in pkgtools.rb used by portupgrade
if [ -d '/usr/local/lib/ruby' ]; then
  echo "/usr/local/lib/ruby is a directory";
  for F in `find /usr/local/lib/ruby -name 'pkgtools.rb' -type f`; do
    UNCHMOD=false;
    echo "patching $F...";
    test -w $F || (chmod u+w $F; UNCHMOD=true);
    sed -e "s/\[script_path(), '-qa', file, \*args\]/[script_path(), '-t', '0', '-qa', file, \*args]/" \
        -e "s/\['\/usr\/bin\/script', '-qa', file, \*args\]/['\/usr\/bin\/script', '-t', '0', '-qa', file, \*args]/" \
        -i '' $F;
    if $UNCHMOD; then chmod u-w $F; fi
  done
fi
