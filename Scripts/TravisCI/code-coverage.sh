#!/usr/bin/env bash

set -euf -o pipefail

UNAME=`uname`;

if [[ $UNAME != "Darwin" ]];
then
    echo "Code coverage for $UNAME is not yet supported. Skip coverage."
    exit 0;
fi

GENERATOR_OUTPUT=`swift package generate-xcodeproj`;
PROJECT_NAME="${GENERATOR_OUTPUT/generated: .\//}";
SCHEME_NAME="${PROJECT_NAME/.xcodeproj/}";

rvm install 2.2.3
gem install xcpretty
WORKING_DIR=$(PWD) xcodebuild \
    -project $PROJECT_NAME \
    -scheme $SCHEME_NAME \
    -sdk macosx10.12 \
    -destination arch=x86_64 \
    -configuration Debug \
    -enableCodeCoverage YES \
    test | xcpretty

bash <(curl -s https://codecov.io/bash)
