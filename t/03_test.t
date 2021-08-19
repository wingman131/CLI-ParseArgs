#!/usr/bin/perl
use strict;
use Test::More;

plan tests => 4;

my $cmd = "./script_01.pl";

my $name = 'Charlie';

# this should fail the Untaint validation and cause the script to die()
my $file = '../../etc/passwd';

my $results = `$cmd -id $$ --long-name $name -f $file -d`;
my @results = split(/\n/, $results);

my $debug_count = count_instances(\@results, "debugging");
is($debug_count, 0, "-d not present");

my $id_count = count_instances(\@results, "-id $$");
is($id_count, 0, "-id not present");

my $l_count = count_instances(\@results, "-l $name");
is($l_count, 0, "-l/--long-name not present");

my $f_count = count_instances(\@results, "-f $file");
is($f_count, 0, "-f not present");

sub count_instances {
	my ($aref, $str) = @_;
	my $count = 0;
	for my $item (@$aref) {
		$count++ if index($item, $str) > -1;
	}
	return $count;
}