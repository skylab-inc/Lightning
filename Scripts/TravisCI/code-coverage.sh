#!/usr/bin/env bash

set -euf -o pipefail

bash <(curl -s https://codecov.io/bash)
