#!/usr/bin/perl
use strict;
use Untaint;
use Test::More;

plan tests => 4;

my $app_root = Untaint::linux_file_path($ENV{'APPLICATION_ROOT'});
my $cmd      = "$app_root/tests/perllib/CLI/ParseArgs/script_01.pl";

my $name = 'Charlie';
my $file = '/var/log/some.log';

my $results = `$cmd -id $$ --long-name $name -f $file -d`;
my @results = split(/\n/, $results);

my $debug_count = count_instances(\@results, "debugging");
is($debug_count, 1, "-d looks good");

my $id_count = count_instances(\@results, "-id $$");
is($id_count, 2, "-id looks good");

my $l_count = count_instances(\@results, "-l $name");
is($l_count, 2, "-l/--long-name looks good");

my $f_count = count_instances(\@results, "-f $file");
is($f_count, 2, "-f looks good");

sub count_instances
{
	my ($aref, $str) = @_;
	my $count = 0;
	for my $item (@$aref)
	{
		$count++ if index($item, $str) > -1;
	}
	return $count;
}