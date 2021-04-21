#!/usr/bin/perl
use strict;
use Untaint;
use CLI::ParseArgs;

my $pa = CLI::ParseArgs->new(
	-synopsis => "Test script for anonymous arguments using CLI::ParseArgs",
	-allow_anonymous_args => 1,
	-valid_args => {
		-d => {req => 0, desc => 'Debugging', debug => 1, no_value => 1},
		-h => {req => 0, desc => 'Foo bar baz', no_value => 1}
	},
);
#print join(',', $pa->list_args());
#print "\n";
#print "help flags: @{$pa->{'help_flag'}}\n";

$pa->process_cli_args();
my @args = $pa->get_anonymous_args();

#print "Cmd line args processed:\n";
print join("\n", @args);
print "\n";
