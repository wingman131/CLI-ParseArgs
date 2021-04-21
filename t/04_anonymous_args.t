#!/usr/bin/perl
use strict;
use Untaint;
use Test::More;

my $app_root   = Untaint::linux_file_path($ENV{'APPLICATION_ROOT'});
my $cmd        = "$app_root/tests/perllib/CLI/ParseArgs/script_03.pl";
my $test_label = "Anonymous args found in output";

my $results = `$cmd foo bar baz`;

if ($results =~ /foo/ && $results =~ /bar/ && $results =~ /baz/) {
	pass($test_label);
}
else {
	fail($test_label);
}

done_testing();
