#!/bin/sh

echo "Test of indicators"
grep -v '^#' lists/TEST.Indicators | bin/test_indicator.sh

echo "Test of signals"

