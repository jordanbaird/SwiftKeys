#!/bin/bash

swift package \
  --allow-writing-to-directory ./docs \
    generate-documentation \
      --target SwiftKeys \
      --disable-indexing \
      --transform-for-static-hosting \
      --hosting-base-path SwiftKeys \
      --output-path ./docs

git checkout documentation
git commit -am "Update documentation"
git push origin documentation
