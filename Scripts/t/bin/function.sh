function diff_is_not_empty {
    file1=$1
    file2=$2
    diff=`diff -u $file1 $file2`
    if [ "$diff" = "" ]; then
	return 1 #ok
    else
	if [ -n "$VERBOSE" ]; then
	    diff -u $file1 $file2
	fi
	return 0
    fi
}

function check_result {
    res=$1
    cmd="$2"
    if [ "$res" != "0" ]; then
	echo "ERROR: a command failed during tests for $indic/$testname/$code:"
	echo "       $cmd"
	if [ -n "$VERBOSE" ]; then
	    echo "The error message is:"
	    cat tmp/errorlog
	fi
    fi
}
