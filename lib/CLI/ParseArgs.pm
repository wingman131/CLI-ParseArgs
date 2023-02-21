package CLI::ParseArgs;

use strict;

our $VERSION = 1.1;

## TODO:
# - Allow valid args to indicate when multiple instances are allowed

sub new {
	my ($class, %args) = @_;

	my $self = bless({}, $class);
	$self->{'valid_args'} = {};
	$self->set_synopsis($args{'-synopsis'}) if exists($args{'-synopsis'});

	if (exists $args{'-valid_args'}) {
		if (ref($args{'-valid_args'}) eq 'HASH') {
			$self->set_valid_args($args{'-valid_args'});
		}
		else {
			die("-valid_args must be a hash reference");
		}
	}
	# else assume valid args will be set with a separate call to set_valid_args()

	if (exists($args{'-auto_help'})) {
		# can enable or disable "auto help" explicitly
		$self->set_auto_help($args{'-auto_help'});
	}
	else {
		# use "auto help" by default
		$self->set_auto_help(1);
	}

	# setting for allowing anonymous (unnamed) arguments, e.g. `script.pl foo bar baz`
	$self->set_allow_anonymous_args($args{'-allow_anonymous_args'} || $args{'-allow_anon_args'});

	$self->_check_for_help_arg();
	$self->_check_for_aliases();

	return $self;
}

sub set_synopsis {
	my ($self, $value) = @_;
	$self->{'synopsis'} = $value;
	return;
}

sub get_synopsis {
	my ($self) = @_;
	return $self->{'synopsis'};
}

sub set_auto_help {
	my ($self, $value) = @_;
	$self->{'auto_help'} = $value;
	return;
}

sub use_auto_help {
	my ($self) = @_;
	return $self->{'auto_help'};
}

sub set_allow_anonymous_args {
	my ($self, $value) = @_;
	$self->{'allow_anonymous_args'} = $value;
	return;
}

sub allow_anonymous_args {
	my ($self) = @_;
	return $self->{'allow_anonymous_args'};
}

sub add_anonymous_arg {
	my ($self, $value) = @_;
	$self->{'anonymous_args'} = [] unless exists($self->{'anonymous_args'});
	push(@{$self->{'anonymous_args'}}, $value);
	return;
}

sub get_anonymous_args {
	my ($self) = @_;
	return if not exists($self->{'anonymous_args'});
	return @{$self->{'anonymous_args'}};
}

sub set_valid_args {
	my ($self, $args_href) = @_;
	$self->set_valid_arg($_, $args_href->{$_}) for (keys %$args_href);
	$self->_check_for_debug_arg();
	$self->_check_for_dry_run_arg();
	return;
}

sub set_valid_arg {
	my ($self, $arg, $options) = @_;
	if (ref($options) ne 'HASH') {
		warn("Invalid options on set_valid_arg() for '$arg' - options should be a hash reference");
		$options = {};
	}
	$self->{'valid_args'}->{$arg} = $options;
	return;
}

sub get_valid_args {
	my ($self) = @_;
	die("Valid arguments have not been set") unless exists($self->{'valid_args'});
	return %{$self->{'valid_args'}} if wantarray;
	return $self->{'valid_args'};
}

sub get_arg_options {
	my ($self, $arg) = @_;
	die("Valid arguments have not been set") unless exists($self->{'valid_args'});
	return $self->{'valid_args'}->{$arg};
}

sub get_arg_option {
	my ($self, $arg, $option) = @_;
	die("Valid arguments have not been set") unless exists($self->{'valid_args'});
	return $self->{'valid_args'}->{$arg}->{$option};
}

sub is_valid_arg {
	my ($self, $arg) = @_;
	return exists($self->{'valid_args'}->{$arg});
}

sub list_args {
	my ($self, $req_only) = @_;

	my @args;
	for my $arg (sort keys(%{$self->{'valid_args'}})) {
		push(@args, $arg) if (!$req_only || ($req_only && $self->{'valid_args'}->{$arg}->{'req'}));
	}

	return @args;
}

sub list_required_args {
	my ($self) = @_;
	return $self->list_args(my $req_only = 1);
}

sub set_arg_value {
	my ($self, $arg, $value) = @_;

	if (exists($self->{'valid_args'}->{$arg}->{'val'})) {
		if (! ref($self->{'valid_args'}->{$arg}->{'val'})) {
			my $tmp_value = $self->{'valid_args'}->{$arg}->{'val'};
			$self->{'valid_args'}->{$arg}->{'val'} = [$tmp_value];
		}

		push(@{$self->{'valid_args'}->{$arg}->{'val'}}, $value);
	}
	else {
		$self->{'valid_args'}->{$arg}->{'val'} = $value;
	}

	return;
}

sub get_arg_value {
	my ($self, $arg) = @_;

	my $value = $self->{'valid_args'}->{$arg}->{'val'};
	if (! defined($value)) {
		my $alias = $self->{'valid_args'}->{$arg}->{'alias'};
		$value = $self->{'valid_args'}->{$alias}->{'val'} if length($alias);
	}

	return $value;
}

sub process_cli_args {
	my ($self) = @_;

	for (my $i = 0; $i <= $#ARGV; $i++) {
		my $arg               = $ARGV[$i];
		my $is_valid_arg_name = $self->is_valid_arg($arg);
		my $next_i            = $i + 1;
		my $value;

		if ($is_valid_arg_name) {
			if ($next_i > $#ARGV || $self->get_arg_option($arg, 'no_value') || $self->is_valid_arg($ARGV[$next_i])) {
				$value = 1;
			}
			else {
				$value = $ARGV[$next_i];
				$i++;
			}
		}

		if ($is_valid_arg_name) {
			$self->validate_arg_value($arg, $value);
			$self->set_arg_value($arg, $value);
		}
		elsif ($self->allow_anonymous_args()) {
			$self->add_anonymous_arg($arg);
		}
		else {
			warn("Invalid argument: '$arg'");
			print($self->help_msg());
			exit(1);
		}
	}

	if (my $debug_flag = $self->get_debug_flag()) {
		$self->debugging($self->get_arg_value($debug_flag));

		if ($self->debugging()) {
			$self->debug_msg("Raw command line arguments: " . join(' ', @ARGV));
			my $msg = "Processed command line arguments:";

			for my $arg ($self->list_args()) {
				my $val = $self->get_arg_value($arg);
				$msg .= " $arg = $val;" if defined($val);
			}

			$self->debug_msg($msg);
		}
	}

	if (my $dry_run_flag = $self->get_dry_run_flag()) {
		$self->is_dry_run($self->get_arg_value($dry_run_flag));
		$self->dry_run_msg("This is a DRY RUN - no changes will be made");
	}

	if (my $help_flag = $self->get_help_flag()) {
		for my $hf (@$help_flag) {
			my $help_val = $self->get_arg_value($hf);
			$self->help($help_val) if defined($help_val);
		}

		if ($self->help()) {
			print $self->help_msg();
			exit(0);
		}
	}

	my $invalid_count = 0;
	for my $arg ($self->list_required_args()) {
		if (! defined($self->get_arg_value($arg))) {
			$invalid_count++;
			warn("Missing required argument: $arg");
		}
	}

	if ($invalid_count > 0) {
		print $self->help_msg();
		exit(2);
	}

	if (wantarray)
	{
		my %args;
		for my $arg ($self->list_args()) {
			my $val = $self->get_arg_value($arg);
			$args{$arg} = $val if defined($val);
		}
		return %args;
	}

	return;
}

sub validate_arg_value {
	my ($self, $arg, $value) = @_;

	my $options = $self->get_arg_options($arg);

	# if no validation is specified, we'll have to assume it's ok
	return unless exists($options->{'validation'});

	my $validation      = $options->{'validation'};
	my $validation_type = ref($validation);

	if ($validation_type eq 'Regexp') {
		return if $value =~ $validation;
	}
	elsif ($validation_type eq 'ARRAY') {
		for my $v (@$validation) {
			if (ref($v) eq 'Regexp') {
				return if $value =~ $v;
			}
			else {
				return if $value eq $v;
			}
		}
	}
	elsif ($validation_type eq 'CODE') {
		return if $validation->($value);
	}
	else {
		warn("Unknown validation type '$validation_type' for '$arg'");
	}

	die("Invalid value for '$arg'");
}

sub help_msg {
	my ($self) = @_;

	my %valid_args = $self->get_valid_args();
	my $help_msg   = "\n"
		. "Help for $0\n"
		. $self->get_synopsis() . "\n"
		. "Parameters:";

	for my $arg (sort keys %valid_args) {
		next if length($valid_args{$arg}->{'is_alias'});
		my $alias = $valid_args{$arg}->{'alias'} ? ", $valid_args{$arg}->{'alias'}" : q{};
		$help_msg .= "\n\t$arg$alias\n\t\t".($valid_args{$arg}->{'req'} ? "*" : "")."$valid_args{$arg}->{'desc'}";
	}

	$help_msg .= "\n\t[Anonymous arguments are allowed]" if $self->allow_anonymous_args();
	$help_msg .= "\n\n";

	return $help_msg;
}

sub get_help_flag {
	my ($self) = @_;
	return $self->{'help_flag'};
}

sub help {
	my ($self, $value) = @_;

	if (@_ == 2) {
		$self->{'help'} = $value;
		return;
	}

	return $self->{'help'};
}

sub _check_for_help_arg {
	my ($self) = @_;

	my %valid_args = $self->get_valid_args();
	$self->{'help_flag'} = [];

	for my $arg (keys %valid_args) {
		if ($valid_args{$arg}->{'help'} || ($arg =~ /-h/ && $valid_args{$arg}->{'desc'} =~ /\bhelp/i)) {
			push(@{$self->{'help_flag'}}, $arg);
			push(@{$self->{'help_flag'}}, $valid_args{$arg}->{'alias'}) if exists($valid_args{$arg}->{'alias'});
			last;
		}
	}

	if (!$self->{'help_flag'}->[0] && $self->use_auto_help()) {
		# every command line program should have a help option
		my @potential_flags = ('-h', '--help');
		for my $flag (@potential_flags) {
			if (! exists($valid_args{$flag})) {
				my $options = {desc => "Show help message", help => 1, no_value => 1};
				$options->{'alias'} = $potential_flags[1] if (
					$flag eq $potential_flags[0]
					&& ! exists($valid_args{$potential_flags[1]})
				);
				$self->set_valid_arg($flag, $options);
				push(@{$self->{'help_flag'}}, $flag);
				push(@{$self->{'help_flag'}}, $options->{'alias'}) if $options->{'alias'};
				last;
			}
		}
	}

	return;
}

sub debug_msg {
	my ($self, $msg) = @_;
	return unless $self->debugging();
	print(STDERR "[debug] $msg\n");
	return 1; # indicate message was output
}

sub get_debug_flag {
	my ($self) = @_;
	return $self->{'debug_flag'};
}

sub debugging {
	my ($self, $value) = @_;

	my $property = 'debugging';
	if (@_ == 2) {
		$self->{$property} = $value;
		return;
	}

	return $self->{$property};
}

sub _check_for_debug_arg {
	my ($self) = @_;

	my %valid_args = $self->get_valid_args();
	for my $arg (keys %valid_args) {
		if ($valid_args{$arg}->{'debug'} || ($arg =~ /-d/i && $valid_args{$arg}->{'desc'} =~ /\bdebug/i)) {
			# allow override for the assumptions made by the second criteria above (e.g. "debug => 0")
			next if (exists($valid_args{$arg}->{'debug'}) && !$valid_args{$arg}->{'debug'});
			$self->{'debug_flag'} = $arg;
			last;
		}
	}

	return;
}

sub dry_run_msg {
	my ($self, $msg) = @_;
	return unless $self->is_dry_run();
	print("[dry-run] $msg\n");
	return 1; # indicate message was output
}

sub get_dry_run_flag {
	my ($self) = @_;
	return $self->{'dry_run_flag'};
}

sub is_dry_run {
	my ($self, $value) = @_;

	my $property = 'is_dry_run';
	if (@_ == 2) {
		$self->{$property} = $value;
		return;
	}

	return $self->{$property};
}

sub _check_for_dry_run_arg {
	my ($self) = @_;

	my %valid_args = $self->get_valid_args();

	for my $arg (keys %valid_args) {
		if ($valid_args{$arg}->{'dryrun'} || $valid_args{$arg}->{'dry_run'}) {
			$self->{'dry_run_flag'} = $arg;
			last;
		}
	}

	return;
}

sub _check_for_aliases {
	my ($self) = @_;

	my %valid_args = $self->get_valid_args();
	for my $arg (keys %valid_args) {
		if (my $alias = $valid_args{$arg}->{'alias'}) {
			my $options = {};
			$options->{$_} = $valid_args{$arg}->{$_} for (keys %{$valid_args{$arg}});
			$options->{'alias'} = $arg;
			$options->{'is_alias'} = 1;
			$self->set_valid_arg($alias, $options);
		}
	}

	return;
}

1;

__END__

=pod

=head1 NAME

CLI::ParseArgs

=head1 SYNOPSIS

Parse command line arguments

=head1 USAGE

 use CLI::ParseArgs;

 my $pa = CLI::ParseArgs->new(
     -synopsis => "A brief description of what this script does (used for help)",
     -valid_args => {
         '-i' => {
             req => 1,
             desc => "[int] Specify ID",
             validation => qr/^\d+$/,
             alias => '--id',
         },
         '-f' => {
             req => 1,
             desc => "[path] Specify file",
             validation => \&Untaint::linux_file_path,
         },
         '-d' => {
             desc => "Show debugging messages (via STDERR)",
             alias => "--debug",
             debug => 1,
             no_value => 1,
         },
         '--dry-run' => {
             desc => "Report what would happen without altering any data",
             no_value => 1,
         },
     }
 );

 my %args = $pa->process_cli_args();

 my $id = $args{'-id'};

 $pa->debug_msg("This is a debug message. It will only show when the debugging argument is indicated");

 ## Alternatively, you get the argument values via method calls:

 $pa->process_cli_args(); # no need to receive the values in a hash

 my $id = $pa->get_arg_value('-id');

 $pa->dry_run_msg("Say what would happen if this was a live run.");

 if (not $pa->is_dry_run()) {
	 # do live-run stuff here
 }

=head1 DESCRIPTION

This module processes command line interface arguments based on specified parameters.

=head1 METHODS

=over

=item new()

Constructor.

Help flags (-h with alias --help) are automatically added unless you tell it not to using `-auto_help => 0`.
It will not override your valid args if you specify those same flags though.
If you specify your own help flags, indicate which argument is for help by adding `help => 1` to the argument's options.

=item process_cli_args()

Process the arguments. If called in list context, it will return them in a hash.

=item set_synopsis()

Set the description of the program.

=item get_synopsis()

Return the description of the program.

=item get_anonymous_args()

Returns a list of anonymous (unnamed) arguments.

Anonymous arguments are not specified in `-valid_args`. To allow them, pass `-allow_anonymous_args => 1` to the constructor.

E.g.

`my_script.pl foo bar baz`

In my_script.pl...

$pa->process_cli_args();

my @args = $pa->get_anonymous_args(); # holds "foo", "bar", "baz"

=item set_valid_args()

Pass in a hash reference with the valid argument definitions. This is called from the constructor if `-valid_args` is passed in.

The format is:

'arg_name' => { options... }

E.g.

 {
     '-i' => {
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
         alias => "--debug",
         debug => 1,
         no_value => 1,
     },
     '--dry-run' => {
         req => 0,
         desc => "Report what would happen without altering any data",
         no_value => 1,
     },
 }

None of the options is required, but "desc" (description) is highly recommended as it is used in the help output to explain the argument.

=item set_valid_arg()

=item get_valid_args()

=item is_valid_arg()

=item get_arg_options()

=item set_arg_value()

=item get_arg_value()

Get the value passed in for the named argument. process_cli_args() must be called first.

E.g. my $id = $pa->get_arg_value('-id');

=item list_args()

Returns a list of all defined argument names/flags.

=item list_required_args()

Returns a list of all defined argument names/flags that are set as required.

=item debugging()

Get or set debugging indicator (true/false).

This will be set automatically if a debugging argument is detected.

=item help()

Get or set help-requested indicator (true/false).

=item help_msg()

Return the help message (string).

=item debug_msg()

Output the specified message to STDERR if debugging is on/true.

=item dry_run_msg()

Output the specified message to STDOUT if dry-run is on/true.

=item is_dry_run()

Get or set dry-run indicator (true/false).

This will be set automatically if a 'dryrun' argument is found.

=head1 BUGS/CAVEATS

None known.

=head1 AUTHOR

John Winger

=head1 COPYRIGHT

(c) Copyright 2023, John Winger.

This program is free software. You may copy or redistribute it under the same terms as Perl itself.

=cut
