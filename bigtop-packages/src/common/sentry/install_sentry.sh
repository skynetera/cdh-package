#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

usage() {
  echo "
usage: $0 <options>
  Required not-so-options:
     --build-dir=DIR             path to sentry dist.dir
     --prefix=PREFIX             path to install into

  Optional options:
     --doc-dir=DIR               path to install docs into [/usr/share/doc/sentry]
     --lib-dir=DIR               path to install hive home [/usr/lib/sentry]
     --installed-lib-dir=DIR     path where lib-dir will end up on target system
     --bin-dir=DIR               path to install bins [/usr/bin]
     --examples-dir=DIR          path to install examples [doc-dir/examples]
     ... [ see source for more similar options ]
  "
  exit 1
}

OPTS=$(getopt \
  -n $0 \
  -o '' \
  -l 'prefix:' \
  -l 'doc-dir:' \
  -l 'lib-dir:' \
  -l 'installed-lib-dir:' \
  -l 'bin-dir:' \
  -l 'examples-dir:' \
  -l 'build-dir:' -- "$@")

if [ $? != 0 ] ; then
    usage
fi

eval set -- "$OPTS"
while true ; do
    case "$1" in
        --prefix)
        PREFIX=$2 ; shift 2
        ;;
        --build-dir)
        BUILD_DIR=$2 ; shift 2
        ;;
        --doc-dir)
        DOC_DIR=$2 ; shift 2
        ;;
        --lib-dir)
        LIB_DIR=$2 ; shift 2
        ;;
        --installed-lib-dir)
        INSTALLED_LIB_DIR=$2 ; shift 2
        ;;
        --bin-dir)
        BIN_DIR=$2 ; shift 2
        ;;
        --examples-dir)
        EXAMPLES_DIR=$2 ; shift 2
        ;;
        --)
        shift ; break
        ;;
        *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

for var in PREFIX BUILD_DIR ; do
  if [ -z "$(eval "echo \$$var")" ]; then
    echo Missing param: $var
    usage
  fi
done

LIB_DIR=${LIB_DIR:-$PREFIX/usr/lib/sentry}
BIN_DIR=${BIN_DIR:-$PREFIX/usr/bin}
install -d -m 0755 $LIB_DIR/lib

TARBALL=`ls ${BUILD_DIR}/build/sentry-*.tar.gz`
DIRECTORY=apache-`basename ${TARBALL/.tar.gz/}`-bin
(cd ${LIB_DIR}/lib && tar --strip-components=2 -xvzf ${TARBALL} ${DIRECTORY}/lib)

install -d -m 0755 ${LIB_DIR}/bin
mv ${BUILD_DIR}/bin/* ${LIB_DIR}/bin

install -d -m 0755 ${LIB_DIR}/sentry
mv ${BUILD_DIR}/LICENSE.txt ${LIB_DIR}/sentry
mv ${BUILD_DIR}/NOTICE.txt ${LIB_DIR}/sentry

install -d -m 0755 ${BIN_DIR}
wrapper=$BIN_DIR/sentry
cat >>$wrapper <<EOF
#!/bin/bash

# Autodetect JAVA_HOME if not defined
. /usr/lib/bigtop-utils/bigtop-detect-javahome

export HADOOP_HOME=\${HADOOP_HOME:-/usr/lib/hadoop}
export SENTRY_HOME=\${SENTRY_HOME:-/usr/lib/sentry}
exec /usr/lib/sentry/bin/sentry "\$@"
EOF

chmod 755 $wrapper

# Cloudera specific
install -d -m 0755 $LIB_DIR/cloudera
cp cloudera/cdh_version.properties $LIB_DIR/cloudera/

# Backwards compatibility
install -d -m 0755 ${PREFIX}/usr/lib/hive/sentry/cloudera
ln -s ../../../sentry/cloudera/cdh_version.properties ${PREFIX}/usr/lib/hive/sentry/cloudera/
