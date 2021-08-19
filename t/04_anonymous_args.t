#!/usr/bin/perl
use strict;
use Test::More;

my $cmd        = "./script_03.pl";
my $test_label = "Anonymous args found in output";

my $results = `$cmd foo bar baz`;

if ($results =~ /foo/ && $results =~ /bar/ && $results =~ /baz/) {
	pass($test_label);
}
else {
	fail($test_label);
}

done_testing();
