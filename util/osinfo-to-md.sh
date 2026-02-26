#!/bin/bash

. /etc/os-release

cat <<EOS
On $PRETTY_NAME runners,
supported \`osinfo\` parameter values are based
on the \`osinfo-db\` package, currently in version
$( dpkg-query -W -f '${Version}\n' osinfo-db 2> /dev/null || rpm -q --qf '%{version}-%{release}\n' osinfo-db ).
Only values for distributions that haven't been marked end-of-life
for extended period of time are shown.

EOS

XSLT_STYLESHEET=${0%.sh}.xslt
( cd /usr/share/osinfo/os && echo '<libosinfo-files>' ; ls */*.xml | sed 's/^/<file>/; s/$/<\/file>/' ; echo '</libosinfo-files>' ) | xsltproc $XSLT_STYLESHEET -
