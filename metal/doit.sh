#!/bin/bash
cd "${0%/*}"
source ./getter-binary.sh units uint64 || exit 1
source ./getter-binary.sh teleports uint64 || exit 1
./show-players || exit 1
./show-active || exit 1
mv *.html ../public_html/metal/ || exit 1
