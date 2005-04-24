#!/bin/sh

. bin/function.sh

# This script launches the various regressions tests on the indicators

(while read indic testname args; do
    tmpfilename="tmp/`echo $indic | sed -e 's/::/_/g'`-$testname"
    filename="`echo $indic | sed -e 's|::|/|g'`"
    for code in "alcatel"; do
	
	bin/output_indicator.pl --interval --code=$code $indic $args >$tmpfilename.$code.interval 2>tmp/errorlog
	check_result $? "bin/output_indicator.pl --interval --code=$code $indic $args"
	
	# Test1 : comparison between --interval and --nointerval
	if [ -z "$WITHOUT_TEST1" ]; then
	bin/output_indicator.pl --nointerval --code=$code $indic $args >$tmpfilename.$code.nointerval 2>tmp/errorlog
	check_result $? "bin/output_indicator.pl --nointerval --code=$code $indic $args"
	if diff_is_not_empty $tmpfilename.$code.interval $tmpfilename.$code.nointerval; then
	    echo "FAILED: calculate and calculate_interval do not return the same result"
	    echo "        for $indic/$testname/$code "
	    echo "        with following params: $args"
	else
	    if [ -n "$VERBOSE" ]; then
		echo "SUCCESS: comparison calculate/calculate_interval for $indic/$testname/$code"
	    fi
	    if [ -z "$KEEP_TMP_FILES" ]; then
		rm $tmpfilename.$code.nointerval
	    fi
	fi
	fi

	# Test between reference data and generated data
	if [ -z "$WITHOUT_TEST2" ]; then
	resultfile="results/$filename/$testname.$code.txt"
	if [ ! -e "$resultfile" ]; then
	    echo "INFO: Generating reference data for $indic/$testname/$code"
	    mkdir -p `dirname $resultfile`
	    cp $tmpfilename.$code.interval $resultfile
	fi
	if diff_is_not_empty $resultfile $tmpfilename.$code.interval; then
	    echo "FAILED: results differs from the reference results"
	    echo "        for $indic/$testname/$code"
	    echo "        with following params: $args"
	else
	    if [ -n "$VERBOSE" ]; then
		echo "SUCCESS: no regression (same results) for $indic/$testname/$code"
	    fi
	fi
	fi
	
	# Clean tmp result file
	if [ -z "$KEEP_TMP_FILES" ]; then
	    rm $tmpfilename.$code.interval
	fi

    done
done;)
