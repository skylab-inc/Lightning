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

    if [[ $UBUNTU_VERSION != "16.04" ]] && [[ $UBUNTU_VERSION != "14.04" ]];
    then
        echo "Ubuntu version $UBUNTU_VERSION is not yet supported.";
        exit 1;
    fi

    OS="ubuntu$UBUNTU_VERSION";
    OS_STRIPPED=`echo $OS | tr -d .`;
    RELEASE_NAME_UPPER="swift-$SWIFT_VERSION-RELEASE";
    RELEASE_NAME_LOWER="swift-$SWIFT_VERSION-release";
    SWIFT_FILENAME="$RELEASE_NAME_UPPER-$OS";

    # Geez, Chris, what're you guys doin' here?
    URL="https://swift.org/builds/$RELEASE_NAME_LOWER/$OS_STRIPPED/$RELEASE_NAME_UPPER/$SWIFT_FILENAME.tar.gz";
    wget $URL
    tar -zxf "$SWIFT_FILENAME.tar.gz";
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift /usr/local/bin/swift
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift-build /usr/local/bin/swift-build
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift-build-tool /usr/local/bin/swift-build-tool
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift-package /usr/local/bin/swift-package
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift-run /usr/local/bin/swift-run
    sudo ln -s $PWD/$SWIFT_FILENAME/usr/bin/swift-test /usr/local/bin/swift-test
fi

echo `swift --version`;
