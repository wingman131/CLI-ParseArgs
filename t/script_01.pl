#!/usr/bin/perl
use strict;
use Untaint;
use CLI::ParseArgs;

my $pa = CLI::ParseArgs->new(
	-synopsis => "Test script 01 for CLI::ParseArgs",
	-valid_args => {
		'-id' => {
			req => 1,
			desc => "[int] Specify ID",
			validation => qr/^\d+$/,
		},
		'-f' => {
			req => 1,
			desc => "[path] Specify file",
			validation => \&Untaint::linux_file_path,
		},
		'-d' => {
			req => 0,
			desc => "Show debugging messages (via STDERR)",
			debug => 1,
		},
		'-l' => {
			req => 0,
			desc => "[str] Specify long name",
			alias => '--long-name'
		},
	}
);

my %args = $pa->process_cli_args();

print "debugging on\n" if $pa->debugging();

my $id1 = $args{'-id'};
print "-id $id1\n";

my $id2 = $pa->get_arg_value('-id');
print "-id $id2\n";

my $file1 = $args{'-f'};
print "-f $file1\n";

my $file2 = $pa->get_arg_value('-f');
print "-f $file2\n";

my $longname1 = $args{'-l'} || $args{'--long-name'};
print "-l $longname1\n";

my $longname2 = $pa->get_arg_value('-l');
print "-l $longname2\n";
