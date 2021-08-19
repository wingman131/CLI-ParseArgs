#!/usr/bin/perl
use strict;
use Test::More;

my $cmd = "./script_01.pl";

subtest "Help triggered by missing arg" => sub {
	my $results = `$cmd -id $$ --long-name Charlie -d`;
	my $help_output_detected = ($results =~ /HELP/i && $results =~ /PARAMETERS:/i);
	ok($help_output_detected, "Missing required arg triggers help");
};

subtest "Help trigger explicitly" => sub {
	my $results = `$cmd -h`;
	my $help_output_detected = ($results =~ /HELP/i && $results =~ /PARAMETERS:/i);
	ok($help_output_detected, "Help triggered with -h");

	$results = `$cmd --help`;
	$help_output_detected = ($results =~ /HELP/i && $results =~ /PARAMETERS:/i);
	ok($help_output_detected, "Help triggered with --help");
};

subtest "Help trigger explicitly when no help is available" => sub {
	my $cmd = "./script_02.pl";

	# in this case, help will be triggered due to missing required args, but should send an exit/error code
	my $err = system($cmd, '-h');
	ok($err, "Error code returned as expected with -h: $err");

	$err = system($cmd, '--help');
	ok($err, "Error code returned as expected with --help: $err");

	# this would normally return a help message if help was not turned off explicitly
	my $results = `$cmd -id $$ -f /some/path/file.log -h`;
	my $help_output_detected = ($results =~ /HELP/i && $results =~ /PARAMETERS:/i);
	ok(!$help_output_detected, "No help message detected: '$results'");
};

done_testing();
