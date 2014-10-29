#!/usr/bin/perl

#$DEBUG=1;

$Home="/home/data/VMS_Data";

# Alpha DNS hostname or IP address
$AlphaAddress="Alpha.Montclair.edu";
# Username and password to telnet/FTP to Alpha with.
$AlphaUser="data"; $AlphaPass="itdata00";
# Remote and local names to use for the SIS text file
$AlphaRemoteSIS = "SIS"; $AlphaSIS = "$Home/SIS.txt";
# Remote and local names to use for the UAF text file
$AlphaRemoteUAF = "SYSUAF.LIS"; $AlphaUAF = "$Home/AlphaUAF.txt";

# Saturn DNS hostname or IP address
$SaturnAddress="Saturn.Montclair.edu";
# Username and password to telnet/FTP to Saturn with.
$SaturnUser="data"; $SaturnPass="itdata00";
# Remote and local names to use for the UAF text file
$SaturnRemoteUAF = "SYSUAF.LIS"; $SaturnUAF = "$Home/SaturnUAF.txt";

use Expect;
use IO::File;
use Net::FTP;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Main script
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

# Run some commands on Alpha
ExecVMS ($AlphaAddress, $AlphaUser, $AlphaPass,
         # Purge the directory.
         "PURGE /KEEP=1 *.*",
         # Do a directory listing
         "DIRECTORY /DATE /SIZE",
         # Delete log files
         "DELETE *.LOG;*",
         # Create the UAF listing.
         "MC AUTHORIZE LIST * /FULL");

# Run some commands on Saturn
ExecVMS ($SaturnAddress, $SaturnUser, $SaturnPass,
         # Purge the directory.
         "PURGE /KEEP=1 *.*",
         # Do a directory listing
         "DIRECTORY /DATE /SIZE",
         # Delete log files
         "DELETE *.LOG;*",
         # Create the UAF listing.
         "MC AUTHORIZE LIST * /FULL");

# FTP to Alpha
$ftp = Net::FTP->new($AlphaAddress, Debug => $DEBUG+0);
$ftp->login("$AlphaUser","$AlphaPass");

# Get the SIS file
$SIS = new IO::File "> $AlphaSIS";
if (defined $SIS) {
  $ftp->get($AlphaRemoteSIS, $SIS);
  $SIS->close;
}

# Get the UAF file
$UAF = new IO::File "> $AlphaUAF";
if (defined $UAF) {
  $ftp->get($AlphaRemoteUAF, $UAF);
  $UAF->close;
}

# Close the FTP connection
$ftp->quit;

# FTP to Saturn
$ftp = Net::FTP->new($SaturnAddress, Debug => $DEBUG+0);
$ftp->login("$SaturnUser","$SaturnPass");

# Get the UAF file
$UAF = new IO::File "> $SaturnUAF";
if (defined $UAF) {
  $ftp->get($SaturnRemoteUAF, $UAF);
  $UAF->close;
}

# Close the FTP connection
$ftp->quit;

print "\n\n***** Done! *****\n\n" if defined $DEBUG;
exit;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
####
#### Subroutine to run commands on a remote VMS system via telnet
####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

sub ExecVMS() {

  # Define variables
  my $prompt = '\$\s+$';
  (my $host, my $user, my $pass)= splice (@_, 0, 3);

  @cmds = @_;

  # Open the telnet session
  $telnet = Expect->spawn("telnet $host") or die "Can't telnet $host";
  $telnet->log_stdout(0) unless defined $DEBUG;

  # Time out if we don't get username within 10 seconds.
  unless ($telnet->expect(10,"Username: ")) {
    die "Never got username prompt" . $telnet->exp_error()."\n";
  }
  print $telnet "$user\r";

  # Time out if we don't get password within 10 seconds.
  unless ($telnet->expect(10,"Password: ")) {
    die "Never got password prompt" . $telnet->exp_error()."\n";
  }
  print $telnet "$pass\r";

  # First, make sure the prompt is set to something we recognize
  while (not($telnet->expect(15, "-re", "$prompt"))) {
    die "Never found prompt" if ($loop++ gt 8);
    print $telnet "SET PROMPT\r";
  }

  # Now that we're in and have a known prompt, let's get to work.
  foreach $cmd (@cmds) {
    print STDERR qq{\n***** Running: "$cmd"\n} if defined $DEBUG;
    print $telnet $cmd . "\r";
    die "Never got prompt back" unless $telnet->expect(600, "-re", "$prompt");
  }

  # Close up shop and go home
  $cmd = "LOGOUT /FULL";
  print STDERR qq{\n***** Running: "$cmd"\n} if defined $DEBUG;
  print $telnet $cmd . "\r";
  $telnet->soft_close();
  return 0;
}
