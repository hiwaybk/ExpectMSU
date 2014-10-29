#!/bin/sh -- # -*- perl -*-
eval 'exec perl $0 ${1+"$@"}'
      if $running_under_some_shell;

# The above should automatically find Perl for you.  If not, check the first
# line to be something like the following:
#!/usr/local/bin/perl

#### Define debugging if we want it.
$DEBUG=7;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Initialization
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

use ExpectMSU;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Subroutines
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

sub RunCiscoCmd($$$$) {
  print qq{Entering RunCiscoCmd()\n} if defined $DEBUG;
  (my $cmd, my $ip, my $pwd, my $prompt) = @_;
  print qq{Running: $cmd\n\ton: IP=$ip; Pwd=$pwd; Prompt=$prompt\n}
    if defined $DEBUG;
  my $router = ExpectMSU->new(
    debug    => ($DEBUG - 1),
    hostname => "$ip",
    ostype   => "Cisco",
    password => "$pwd",
    prompt   => "$prompt",
    pager    => "--More--"
  );
  return $router->execute($cmd);
}

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Main
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

# Get information
$ip = shift or die qq{Specify the IP address to connect to.\n};
$pass = shift or die qq{Specify the password to authenticate with.\n};
$prompt = shift or die qq{Specify the prompt the router uses.\n};
$command = shift or die qq{Specify the command to run.\n};

# Split the output into an arrary, one line per element
print RunCiscoCmd($command, $ip, $pass, $prompt);
# @table = split(/[\n\r]+/, RunCiscoCmd($command, $ip, $pass, $prompt));

# Print eveything out
print "\n" . join("\n", @table) . "\n";
