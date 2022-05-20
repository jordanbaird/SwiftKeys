#!/bin/bash

STV="swift-tools-version:"
VERSION=$(cat ./Package.swift | grep $STV | sed -e "s/$STV/ /" | awk {'print $NF'})

if cat ./README.md | grep -qE "!\[Swift Version\]\(.+\)"; then
    echo "UPDATING..."
    sed -r -i -e "s/(Swift-)([0-9]+.[0-9]+)/\1$VERSION/g" ./README.md
else
    echo "README file does not contain a ![Swift Version](...) tag."
fi
