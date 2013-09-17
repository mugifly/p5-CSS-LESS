package CSS::LESS;

use warnings;
use strict;
use Carp;
use File::Temp qw//;
use IPC::Open3;

use version; our $VERSION = qv('0.0.1');

sub new {
	my ($class, %params) = @_;
	my $s = bless({}, $class);

	$s->{dont_die} = $params{dont_die} || 0;
	$s->{dry_run} = $params{dry_run};
	$s->{paths_include} = $params{include_paths}; # Array
	$s->{path_lessc_bin} = $params{lessc_path} || 'lessc';
	$s->{path_tmp} = $params{tmp_path} || undef;

	$s->{last_error} = undef;

	return $s;
}

# Ccompile a less style-sheet (return: Compiled CSS style-sheet)
sub compile {
	my $s = shift;
	my $buf = shift;
	# Compile less to css
	return $s->_exec_lessc('content' => $buf);
}

# Get last error
sub last_error {
	my $s = shift;
	return $s->{last_error};
}

# Check for lessc has installed
sub is_lessc_installed {
	my $s = shift;
	my $lessc_ver = $s->_exec_lessc('version' => undef);
	if($lessc_ver =~ /^lessc .*(LESS Compiler).*/i) {
		return 1;
	}
	return 0;
}

# Execute a command with lessc
sub _exec_lessc {
	my ($s, %options) = @_;

	# Prepare a command
	my ($cmd_args_ref, $path_tmpfile) = $s->_generate_cmd_lessc(%options);
	my @cmd_args = @{$cmd_args_ref};

	# Execute a command

	if($s->{dry_run}){ # Dry run
		$" = ' ';
		return "@cmd_args"; # return generated command
	}

	my ($fh_in, $fh_out, $fh_err);
	#open $fh, '-|', @cmd_args, '2>&1' or die('Can not open a pipe to:'. $s->{path_lessc_bin});
	my $pid = IPC::Open3::open3($fh_in, $fh_out, 0, @cmd_args);
	my ($ret);
	while (my $l = <$fh_out>) {
		$ret .= $l;
	}
	waitpid($pid, 0);

	# Error process
	if($? != 0){
		$s->{last_error} = $ret;
		unless($s->{dont_die}){
			if(defined $ret){
				die ('Compile error: '. $ret);
			} else {
				die ('Compile error: Unknown');
			}
		}
	}
	# Delete tmp file
	if(defined $path_tmpfile){
		unlink($path_tmpfile);
	}

	return $ret;
}

# Generate a command for lessc (Return: \@args, $path of temp-file)
sub _generate_cmd_lessc {
	my ($s, %options) = @_;
	my @cmd_args = ();

	# Execute path
	push(@cmd_args, $s->{path_lessc_bin});

	# Process for content
	my $path_tmpfile;
	if(defined $options{content}) {
		my $content = $options{content};
		delete $options{content};

		my $tempfh;
		($tempfh, $path_tmpfile) = File::Temp::tempfile(DIR => $s->{path_tmp});
		print $tempfh $content;
		close($tempfh);

		push(@cmd_args, $path_tmpfile);
	}

	# Process for include paths
	if(defined $s->{paths_include}){
		if(@{$s->{paths_include}} <= 1){
			push(@cmd_args, '--include-path='.$s->{paths_include}->[0]);
		} else {
			my $paths = '--include-path=';
			{
				local $" = ':';
				$paths .= "@{$s->{paths_include}}";
			}
			$paths .= '';
			push(@cmd_args, $paths);
		}
	}

	# Process for other parameters
	foreach my $key (keys %options) {
		if(defined $options{$key}){
			push(@cmd_args, "--".$key."=".$options{$key});
		} else {
			push(@cmd_args, "--".$key);
		}
	}

	push(@cmd_args, '--verbose');
	
	# Return a args (with command path) and a path of temp-file
	return (\@cmd_args, $path_tmpfile);
}

1;
__END__=head1 NAME

CSS::LESS - Compile LESS stylesheet files (.less) using lessc

=head1 SYNOPSIS

  use CSS::LESS;
  # Compile a single LESS stylesheet
  my $less = CSS::LESS->new();
  my $css = $less->compile('a:link { color: lighten('#000000', 10%); }');
  print $css."\n";

  # Compile a LESS stylesheets with using @include syntax of LESS.
  $less = CSS::LESS->new( include_paths => ['/foo/include/'] );
  $css = $less->compile('@import (less) 'bar.less'; div { width: 100px; }');
  print $css."\n";

=head1 REQUIREMENTS

=head2 lessc

It must installed, because this module is wrapper of "lessc".

You can install "lessc" using "npm" (Node.js Package Manager).

    $ npm install -g less
    $ lessc -v
    lessc x.x.x (LESS Compiler) [JavaScript]

=head1 METHODS

=head2 new ( [%params] )

Create an instance of CSS::LESS.

=head3 %params : 

=over 4

=item * include_paths - Path of include .less files. 

This paths will be used for the @include syntax of .less stylesheet.

Note: If you set a extrinsic variable value to it, you must be careful. (It means such as set a value by user-input on the Web-application. Because it has matter of concern that like a directory-traversal ).

=item * lessc_path - Path of LESS compiler (default: 'lessc' on the PATH.)

=item * dry_run - Dry-run mode for debug. (default: 0)

=item * dont_die - (default: 0)

=item * tmp_path - Path of save for temporally files.

=back

=head2 compile ( $content )

Parse a LESS (.less) stylesheet, and compile to CSS (.css) stylesheet.

If you would prefer to compile from a file, firstly, please read a file with using the "File::Slurp" module or open method as simply. Then, parse it with this 'compile' method.

=head2 is_lessc_installed ( )

Check for lessc has installed.

=head2 last_error ()

Get a message of last error. (This method is useful only if 'dont_die' option is set when initialized an instance.)

=head1 SEE ALSO

L<http://lesscss.org/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, Masanori Ohgita (http://ohgita.info/).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
