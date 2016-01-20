do util.do

set tests_avail [list minimal arith memory jump fwd ctrl]

if { $argc == 1 && $1 == "-help" } {
    echo "testbench parameter missing"
    echo "usage: do level1.do TEST_NAME"
    echo ""
    echo "Supported tests: ${tests_avail}"
    return
}

if { $argc == 1 } {
    set tests_avail $1
}

set summary [list]
set total_count 0
set total_failed 0

onbreak { resume }

foreach test $tests_avail {
    load_test "testbench/level1/data/${test}.tc"
    load_testbench level1

        if { [load_program ${test}] == 0 } {
                force sim:/level1_tb/no_test true
        }

    run -all

    set fail_count [examine -radix unsigned sim:/level1_tb/fail_count]
    set test_count [examine -radix unsigned sim:/level1_tb/total_count]
    set total_count [expr $total_count + $test_count]
    set total_failed [expr $total_failed + $fail_count]
    lappend summary "${test} ${fail_count}/${test_count}"
}

echo "Summary"
echo "-------"
foreach line $summary {
    echo $line
}
echo "-------"
echo "Total ${total_failed}/${total_count}"