use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.17;

my %WriteMakefileArgs = (
	"ABSTRACT" => "Parse command line arguments in a Perl script",
	"AUTHOR" => "John Winger <john.winger\@protonmail.com>",
	"CONFIGURE_REQUIRES" => {
		"ExtUtils::MakeMaker" => "6.17",
	},
	"DISTNAME" => "CLI-ParseArgs",
	"LICENSE" => "MIT",
	"MIN_PERL_VERSION" => "5.006",
	"NAME" => "CLI::ParseArgs",
	"PREREQ_PM" => {
		"strict" => 0,
	},
	"TEST_REQUIRES" => {
		"Test::More" => "0.96",
		"strict" => 0,
	},
	"VERSION" => "1.0",
	"test" => {
		"TESTS" => "t/*.t",
	},
);

my %FallbackPrereqs = (
	"Test::More" => "0.96",
	"strict" => 0
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.63_03) }) {
	delete $WriteMakefileArgs{'TEST_REQUIRES'};
	delete $WriteMakefileArgs{'BUILD_REQUIRES'};
	$WriteMakefileArgs{'PREREQ_PM'} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{'CONFIGURE_REQUIRES'} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
