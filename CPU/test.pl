# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Sys::CPU;
$loaded = 1;
print "ok 1\n";

$number = Sys::CPU::cpu_count();
print "ok 2 ($number)\n";

$speed = Sys::CPU::cpu_clock($number);
print "ok 3 ($speed)\n";

$type = Sys::CPU::cpu_type($number);
print "ok 4 ($type)\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

