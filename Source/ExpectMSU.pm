#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

package ExpectMSU;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

# Require the Expect.pm package
use Expect; # or die qq{Expect.pm MUST be installed!};;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.20';

my %settings = (
  debug => 0,
  hostname => "localhost",
  ostype => "",
  username => "",
  password => "",
  timeout => 15,
  loopAttempts => 2,
  prompt => "j u n k",
  pager => "j u n k",
  expect => "",
  maximum_buffer_length => "655360"
);

# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
####
#### Routines to create new connections.
####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
sub new {

  # Determine our class.
  my $class = shift;

  # Create a new object.
  print STDERR qq{Creating a new object.\n} if ($settings{debug} > 0);
  my $self = bless {}, $class;

  # Parse any settings.
  print STDERR qq{Reading settings.\n} if ($settings{debug} > 0);
  $self->settings (@_);

  # Initialize the connection.
  print STDERR qq{Initializing connection.\n} if ($settings{debug} > 0);
  $self->_initialize;

  # We're done.
  print STDERR qq{Object creation complete.\n} if ($settings{debug} > 0);
  return $self;
}

sub settings {

  my $self = shift;

  # Get function parameters.
  print STDERR qq{Reading parameters.\n} if ($settings{debug} > 0);
  my %hash = @_;
  my $key;
  foreach $key (keys %hash) {
    if (defined $settings{$key}) {
      $settings{$key} = $hash{$key};
    } else {
      die qq{Invalid option "$key"};
    }
  }

  # Check the timeout value.
  die ("Invalid value for timeout") unless ($settings{timeout} > 0);

  # Check the ostype.
  $settings{ostype} = lc $settings{ostype};

  # Check the debug value (make sure it's numeric and under 3).
  $settings{debug} += 0;
  $settings{debug}++ while ($settings{debug} < 0);
  $settings{debug}-- while ($settings{debug} > 3);

  # Check the timeout value (make sure it's numeric and at least 5).
  $settings{timeout} += 0;
  $settings{timeout}++ while ($settings{timeout} < 4);

  if ($settings{debug} > 0) {
    print STDERR "Settings:\n";
    foreach $key (keys %settings) {
      print STDERR "$key: $settings{$key}\n";
    }
    print STDERR "\n";
  }

  return 0;
}

sub execute {
  my $self = shift;
  my $cmd = shift;

  $self->settings (@_) if (@_);

  my $expect = $settings{expect};
  #$expect->slave->stty(qw(raw));

  print STDERR qq{\n***** Running: "$cmd"\n} if ($settings{debug} > 0);
  print $expect "$cmd\r";
  my $match; my $loop = 1; my $count; my $output; my @output; my @text;
  my $output = "";
  while ($loop) {
    $match = $expect->expect( $settings{timeout},
                                "-re", "$settings{prompt}",
                                "-re", "$settings{pager}");
    die "Never got prompt or pager.\n" unless $match;
    $output .= $expect->exp_before();
    _printExpectDebug("prompt", $output);
    $loop = $match - 1;
    $count++;
    print STDERR "Waiting for prompt ($count)\n" if $settings{debug};
    print $expect " " if $loop;
  }
  $output .= $expect->clear_accum();
  my @output = split(/\n/, $output);
  push (@text, @output);
  my $results = join("\n", @text) . "\n";
  $results =~ s/\e\[7m\n\e\[0m\010+//g;
  return $results;
}

sub close {
  my $self = shift;
  $self->DESTROY;
}

sub DESTROY {
  my $self = shift;

  # Close the connection for the given OS.
  print STDERR qq{Determining OS type.\n} if ($settings{debug} > 0);
  if ($settings{ostype} eq "vms") {
    print STDERR qq{VMS OS type.\n} if ($settings{debug} > 0);
    $self->_close_vms;
  } elsif ($settings{ostype} eq "cisco" ) {
    print STDERR qq{Cisco OS via Telnet type.\n} if ($settings{debug} > 0);
    $self->_close_cisco;
  } elsif ($settings{ostype} eq "ciscossh" ) {
    print STDERR qq{Cisco OS via SSH type.\n} if ($settings{debug} > 0);
    $self->_close_ciscossh;
  } elsif ($settings{ostype} eq "unixssh" ) {
    print STDERR qq{Unix SSH type.\n} if ($settings{debug} > 0);
    $self->_close_unixssh;
  } elsif ($settings{ostype} eq "merussh" ) {
    print STDERR qq{Meru SSH type.\n} if ($settings{debug} > 0);
    $self->_close_unixssh;
  } elsif ($settings{ostype} eq "hpswitchos" ) {
    print STDERR qq{HP switch OS via telnet type.\n} if ($settings{debug} > 0);
    $self->_close_hpswitch;
  } else {
    die qq{Invalid OS type defined "$settings{ostype}"};
  }
}

sub _initialize {

  my $self = shift;

  # Initialize the connection for the given OS.
  print STDERR qq{Determining OS type.\n} if ($settings{debug} > 0);
  if ($settings{ostype} eq "vms") {
    print STDERR qq{VMS OS type.\n} if ($settings{debug} > 0);
    $self->_initialize_vms;
  } elsif ($settings{ostype} eq "cisco" ) {
    print STDERR qq{Cisco OS via Telnet type.\n} if ($settings{debug} > 0);
    $self->_initialize_cisco;
    print STDERR qq{Running "term len 0"\n} if ($settings{debug} > 0);
    $self->execute("term len 0");
  } elsif ($settings{ostype} eq "ciscossh" ) {
    print STDERR qq{Cisco OS via SSH type.\n} if ($settings{debug} > 0);
    $self->_initialize_ciscossh;
    print STDERR qq{Running "term len 0"\n} if ($settings{debug} > 0);
    $self->execute("term len 0");
  } elsif ($settings{ostype} eq "unixssh" ) {
    print STDERR qq{Unix via SSH type.\n} if ($settings{debug} > 0);
    $self->_initialize_unixssh;
  } elsif ($settings{ostype} eq "merussh" ) {
    print STDERR qq{Meru via SSH type.\n} if ($settings{debug} > 0);
    $self->_initialize_merussh;
  } elsif ($settings{ostype} eq "hpswitchos" ) {
    print STDERR qq{HP switch OS via telnet type.\n} if ($settings{debug} > 0);
    $self->_initialize_hpswitch;
  } else {
    die qq{Invalid OS type defined "$settings{ostype}"};
  }

  # Define settings for the connection.
  my $expect = $settings{expect};
  my $maximum_buffer_length = $settings{maximum_buffer_length};
  if ($maximum_buffer_length > 0) {
    my $current_buffer_length = $expect->max_accum();
    print STDERR qq{Setting max_accum (maximum_buffer_length) to "$maximum_buffer_length" from "$current_buffer_length".\n} if ($settings{debug} > 0);
    $expect->max_accum($maximum_buffer_length);
  }

}

sub _initialize_hpswitch {

  my $self = shift;
  my $expect;

  # Open the telnet session
  print STDERR "Running telnet.\n" if $settings{debug};
  $expect = Expect->spawn("telnet $settings{hostname}")
    or die "Can't telnet $settings{hostname}\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  print STDERR "Waiting for password prompt.\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},"Enter password: ")) {
    die "Never got password prompt " . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Enter password: ", $expect->exp_before());

  # First, make sure the prompt is set to something we recognize
  print STDERR "Waiting for prompt.\n" if $settings{debug};
  my $loop=0;
  while (not( $expect->expect( $settings{timeout}, "-re", $settings{prompt}))) {
    die "Never found $settings{prompt}.\n" if ($loop++ > $settings{loopAttempts});
    print $expect "\r";
  }
  _printExpectDebug("$settings{prompt}", $expect->exp_before());
}

sub _close_hpswitch {
  my $self = shift;

  my $cmd = "exit";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}





sub _initialize_cisco {

  my $self = shift;
  my $expect;

  # Open the telnet session
  print STDERR "Running telnet.\n" if $settings{debug};
  $expect = Expect->spawn("telnet $settings{hostname}")
    or die "Can't telnet $settings{hostname}\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  if ($settings{'username'}) {
    print STDERR "Waiting for username prompt.\n" if $settings{debug};
    unless ( $expect->expect( $settings{timeout},"Username: ")) {
      die "Never got username prompt " . $expect->exp_error()."\n";
    }
    print $expect "$settings{username}\r";
    _printExpectDebug("Username: ", $expect->exp_before());
  }

  my $pass_prompt = "assword: ";
  print STDERR "Waiting for password prompt ($pass_prompt).\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},$pass_prompt)) {
    die "Never got password prompt ($pass_prompt) " . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Password: ", $expect->exp_before());

  # First, make sure the prompt is set to something we recognize
  print STDERR "Waiting for prompt (" . $settings{prompt} . ").\n" if $settings{debug};
  my $loop=0;
  while (not( $expect->expect( $settings{timeout}, "-re", $settings{prompt}))) {
    die "Never found $settings{prompt}.\n" if ($loop++ > $settings{loopAttempts});
    print $expect "\r";
  }
  _printExpectDebug("$settings{prompt}", $expect->exp_before());
}

sub _close_cisco {
  my $self = shift;

  my $cmd = "exit";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}





sub _initialize_ciscossh {

  my $self = shift;
  my $expect;

  # Open the telnet session
  print STDERR "Running SSH.\n" if $settings{debug};
  my $cmd = "ssh $settings{username}\@$settings{hostname}";
  print STDERR qq{Command: $cmd\n} if ($settings{debug} > 0);
  $expect = Expect->spawn($cmd)
    or die "Can't SSH!\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  print STDERR "Waiting for password prompt.\n" if $settings{debug};
  my $pass_prompt = "assword: ";
  unless ( $expect->expect( $settings{timeout},$pass_prompt)) {
    die "Never got password prompt ($pass_prompt) " . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Password: ", $expect->exp_before());

  # First, make sure the prompt is set to something we recognize
  print STDERR "Waiting for prompt.\n" if $settings{debug};
  my $loop=0;
  while (not( $expect->expect( $settings{timeout}, "-re", $settings{prompt}))) {
    die "Never found $settings{prompt}.\n" if ($loop++ > $settings{loopAttempts});
    print $expect "\r";
  }
  _printExpectDebug("$settings{prompt}", $expect->exp_before());
}

sub _close_ciscossh {
  my $self = shift;

  my $cmd = "exit";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}





sub _initialize_unixssh {

  my $self = shift;
  my $expect;

  # Open the telnet session
  print STDERR "Running SSH.\n" if $settings{debug};
  $expect = Expect->spawn("ssh $settings{username}\@$settings{hostname}")
    or die "Can't SSH $settings{username}\@$settings{hostname}\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  print STDERR "Waiting for password prompt.\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},"Password: ")) {
    die "Never got password prompt " . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Password: ", $expect->exp_before());

  # First, make sure the prompt is set to something we recognize
  print STDERR "Waiting for prompt.\n" if $settings{debug};
  my $loop=0;
  while (not( $expect->expect( $settings{timeout}, "-re", $settings{prompt}))) {
    die "Never found $settings{prompt}.\n" if ($loop++ > $settings{loopAttempts});
    print $expect "\r";
  }
  _printExpectDebug("$settings{prompt}", $expect->exp_before());
}

sub _close_unixssh {
  my $self = shift;

  my $cmd = "exit";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}










sub _initialize_merussh {

  my $self = shift;
  my $expect;

  # Open the telnet session
  print STDERR "Running SSH.\n" if $settings{debug};
  $expect = Expect->spawn("ssh $settings{username}\@$settings{hostname}")
    or die "Can't SSH $settings{username}\@$settings{hostname}\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  print STDERR "Waiting for password prompt.\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},"password: ")) {
    die "Never got password prompt " . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Password: ", $expect->exp_before());

  # First, make sure the prompt is set to something we recognize
  print STDERR "Waiting for prompt.\n" if $settings{debug};
  my $loop=0;
  while (not( $expect->expect( $settings{timeout}, "-re", $settings{prompt}))) {
    die "Never found $settings{prompt}.\n" if ($loop++ > $settings{loopAttempts});
    print $expect "\r";
  }
  _printExpectDebug("$settings{prompt}", $expect->exp_before());
}

sub _close_merussh {
  my $self = shift;

  my $cmd = "exit";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}










sub _initialize_vms {

  my $self = shift;
  my $expect;

  $settings{prompt} = '\$\s+$';

  # Open the telnet session
  print STDERR "Running telnet.\n" if $settings{debug};
  $expect = Expect->spawn("telnet $settings{hostname}")
    or die "Can't telnet $settings{hostname}\n";
  $settings{expect} = $expect;
  $expect->log_stdout(0);

  # Time out if we don't get username.
  print STDERR "Waiting for Username: prompt.\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},"Username: ")) {
    die "Never got username prompt" . $expect->exp_error() . "\n";
  }
  print $expect "$settings{username}\r";
  _printExpectDebug("Username: ", $expect->exp_before());

  print STDERR "Waiting for Password: prompt.\n" if $settings{debug};
  unless ( $expect->expect( $settings{timeout},"Password: ")) {
    die "Never got password prompt" . $expect->exp_error()."\n";
  }
  print $expect "$settings{password}\r";
  _printExpectDebug("Password: ", $expect->exp_before());

  print STDERR "Waiting for prompt.\n" if $settings{debug};
  # First, make sure the prompt is set to something we recognize
  my $loop=0;
  my $delay = int($settings{timeout}/10);
  while (not( $expect->expect($delay, "-re", $settings{prompt}))) {
    die "Never found prompt.\n" if ($loop++ > $settings{loopAttempts});
    print STDERR "Loop pass $loop ($delay seconds).\n"
      if ($settings{debug} > 0);
    print $expect "SET PROMPT\r";
  }
  _printExpectDebug("\$", $expect->exp_before());
}

sub _close_vms {
  my $self = shift;

  my $cmd = "LOGOUT /FULL";
  my $expect=$settings{expect};

  print STDERR qq{\n***** Running: "$cmd"\n} if $settings{debug};
  print $expect "$cmd\r";
  $expect->soft_close();
  $settings{expect} = undef;
  return 0;
}

sub _printExpectDebug {

  my $search = shift @_;
  my $result = shift @_;

  if ($settings{debug} > 1) {
    print STDERR qq{**** Received the following while waiting for "$search".\n};
    my $line;
    my $char;
    foreach $line (split(/\n/, $result)) {
      $line =~ s/[\r\n]*$//;
      foreach $char (split(//, $line)) {
        if (not ((32 <= ord($char)) and (ord($char) <= 126))) {
          $char = ord($char);
          $char = "ESC" if $char eq 27;
          $char = "CR" if $char eq 13;
          $char = "<" . $char . ">";
        }
        print STDERR $char;
      }
      print STDERR "\n";
    }
    print STDERR qq{**** Found "$search".\n};
  }
}

1;
__END__

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
####
#### Below is the stub of documentation for your module. You better edit it!
####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

=head1 NAME

ExpectMSU - Perl/Expect object to execute commands on a remote system

=head1 SYNOPSIS

  use ExpectMSU;

=head1 DESCRIPTION

This extension provides an easy interface to execute commands
on a remote system via telnet.

$router = ExpectMSU->new(
    debug    => "$DEBUG",
    hostname => "$ip",
    ostype   => "Cisco",
    password => "$pwd",
    prompt   => "$prompt",
    pager    => "--More--"
);

print $router->execute("show ip int br");

=head1 AUTHOR

Brian Kelly, Brian.Kelly@Montclair.edu

=head1 SEE ALSO

perl(1).

=cut
