#!/bin/sh

set -e

echo "Removing existing data directory"
rm -rf ./data
echo "Existing data directory removed"
cd certs && ./generate.sh --skip-generation
