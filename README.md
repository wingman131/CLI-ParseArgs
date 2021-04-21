# CLI::ParseArgs

## SYNOPSIS

Parse command line arguments in a Perl script.

This OO module processes command line interface arguments based on specified parameters.

## USAGE

```perl
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
 );

 my %args = $pa->process_cli_args();

 # the primary arg name or the alias both work as the key to retrieve the value
 my $id = $args{'--id'};

 $pa->debug_msg("This is a debug message. It will only show when the debugging argument is indicated");

 ## Alternatively, you get the argument values via method calls:

 $pa->process_cli_args(); # no need to receive the values in a hash

 my $id = $pa->get_arg_value('-i');
```

## METHODS

* `new()`

  Constructor.

  Help flags (`-h` with alias `--help`) are automatically added unless you tell it not to using `-auto_help => 0`.

  It will not override your valid args if you specify those same flags though.

  If you specify your own help flags, indicate which argument is for help by adding `help => 1` to the argument's options.

* `process_cli_args()`

  Process the arguments. If called in list context, it will return them in a hash.

* `set_synopsis()`

  Set the description of the program.

* `get_synopsis()`

  Return the description of the program.

* `get_anonymous_args()`

  Returns a list of anonymous (unnamed) arguments.

  Anonymous arguments are not specified in `-valid_args`. To allow them, pass `-allow_anonymous_args => 1` to the constructor.

  E.g.

  `my_script.pl foo bar baz`

  In my_script.pl...

  ```perl
  $pa->process_cli_args();

  my @args = $pa->get_anonymous_args(); # holds "foo", "bar", "baz"
  ```

* `set_valid_args()`

  Pass in a hash reference with the valid argument definitions. This is called from the constructor if `-valid_args` is passed in.

  The format is:

  `'arg_name' => { options... }`

  E.g.

  ```perl
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
  ```

  None of the options is required, but "desc" (description) is highly recommended as it is used in the help output to explain the argument.

* `set_valid_arg()`

* `get_valid_args()`

* `is_valid_arg()`

* `get_arg_options()`

* `set_arg_value()`

* `get_arg_value()`

  Get the value passed in for the named argument. process_cli_args() must be called first.

  E.g. `my $id = $pa->get_arg_value('-id');`

* `list_args()`

  Returns a list of all defined argument names/flags.

* `list_required_args()`

  Returns a list of all defined argument names/flags that are set as required.

* `debugging()`

  Get or set debugging indicator (true/false).

  This will be set automatically if a debugging argument is detected.

* `help()`

  Get or set help-requested indicator (true/false).

* `help_msg()`

  Return the help message (string).

* `debug_msg()`

  Output the specified message to STDERR if debugging is on/true.

## BUGS/CAVEATS

None known.

## AUTHOR

John Winger

## COPYRIGHT

(c) Copyright 2021, John Winger.

This program is free software. You may copy or redistribute it under the same terms as Perl itself.
