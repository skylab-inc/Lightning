#!/usr/bin/env bash

set -euf -o pipefail

UNAME=`uname`;
echo "Unix Platform: $UNAME";

if [[ $UNAME != "Linux" ]] && [[ $UNAME != "Darwin" ]];
then
    echo "$UNAME is not yet supported.";
    exit 1;
fi

if [[ $UNAME == "Linux" ]];
then
    UBUNTU_VERSION=`lsb_release -r -s`;

    echo "Installing Swift on Ubuntu $UBUNTU_VERSION."

    if [[ $UBUNTU_VERSION != "15.10" ]] && [[ $UBUNTU_VERSION != "14.04" ]];
    then
        echo "Ubuntu version $UBUNTU_VERSION is not yet supported.";
        exit 1;
    fi

    OS="ubuntu$UBUNTU_VERSION";
    OS_STRIPPED=`echo $OS | tr -d .`;
    RELEASE_NAME_UPPER="swift-$SWIFT_VERSION-RELEASE";
    RELEASE_NAME_LOWER="swift-$SWIFT_VERSION-release";
    SWIFT_FILENAME="$RELEASE_NAME_UPPER-$OS.tar.gz";

    # Geez, Chris, what're you guys doin' here?
    URL="https://swift.org/builds/$RELEASE_NAME_LOWER/$OS_STRIPPED/$RELEASE_NAME_UPPER/$SWIFT_FILENAME";
    wget $URL
    tar -zxf $SWIFT_FILENAME;
    export PATH=$PWD/$SWIFT_FILENAME/usr/bin:"${PATH}";
fi

echo `swift --version`;

swift build
swift build -c release
swift test
