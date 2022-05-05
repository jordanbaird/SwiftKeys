#!/bin/bash

DEBUG_FOLDER=".build/debug"
TESTS="$DEBUG_FOLDER/SwiftKeysPackageTests.xctest/Contents/MacOS/SwiftKeysPackageTests"
PROFILE="$DEBUG_FOLDER/codecov/default.profdata"

xcrun llvm-cov \
  export -format="lcov" $TESTS \
  -instr-profile $PROFILE > info.lcov
