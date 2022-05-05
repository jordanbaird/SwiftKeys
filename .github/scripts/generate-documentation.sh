#!/bin/bash

CHANGED_FILES=$(git status -s)

# See if any files have changed. If so, stash them.
if [[ $CHANGED_FILES ]]
then
  git stash
fi

# Generate and commit the docs.
swift package \
  --allow-writing-to-directory ./docs \
    generate-documentation \
      --target SwiftKeys \
      --disable-indexing \
      --transform-for-static-hosting \
      --hosting-base-path SwiftKeys \
      --output-path ./docs
      
git commit -am "Update documentation"

# Reapply the stash, if needed.
if [[ $CHANGED_FILES ]]
then
  git stash apply -q
fi
