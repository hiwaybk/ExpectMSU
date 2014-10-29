#!/bin/sh -- # -*- perl -*-
eval 'exec perl $0 ${1+"$@"}'
      if $running_under_some_shell;

# The above should automatically find Perl for you.  If not, check the first
# line to be something like the following:
#!/usr/local/bin/perl

#### Define debugging if we want it.
#$DEBUG=3;

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### User settings
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

# Define the settings for the routers we will collect arp data from
@ROUTERS = (
  "putRouterIpHere|putPassHere|putRouterPromptHere",
);

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Initialization
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

use ExpectMSU;

# Get the current timestamp
#  0    1    2     3     4    5     6     7     8
#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
my @time = localtime();
$time[4] += 1;
$time[5] += 1900;
my $timestamp = sprintf("%d/%d/%d %d:%d:00", $time[4], $time[3], $time[5],
                                             $time[2], $time[1]);

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Subroutines
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

sub GetCurrentInfo(@) {
  print qq{Entering GetCurrentInfo()\n} if defined $DEBUG;
  my @routers = @_;
  print qq{Received:\n\t} . join ("\n\t", @routers) . "\n" if defined $DEBUG;
  my %ip2mac;
  foreach $router (@routers) {
    my %temp = GetRouterTable($router);
    foreach my $ip (keys %temp) {
      if (not defined $ip2mac{$ip}) {
        $ip2mac{$ip} = $temp{$ip};
      } else {
        die qq{IP ($ip) defined twice ($ip2mac{$ip} and $temp{$ip})}
          unless ($ip2mac{$ip} eq $temp{$ip});
      }
    }
  }
  return %ip2mac;
}

sub GetRouterTable($) {
  print qq{Entering GetRouterTable()\n} if defined $DEBUG;
  my %ip2mac;
  my $cmd = qq{show ip arp};
  my @table = split(/[\n|\r]/, RunCiscoCmd($cmd, split(/\|/, shift)));
  print qq{Found:\n\t}.join("\n\t",@table).qq{\n} if ($DEBUG > 2);
  # Parse the arp table
  foreach (@table) {
    chomp;
    (my $proto, my $ip, my $age, my $mac, my $type, my $int) = split;
    next unless $ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;
    next unless $mac =~ /[\da-f]{4}\.[\da-f]{4}\.[\da-f]{4}/i;
    $ip = sortableIP($ip);
    next if ($mac eq "0000.0000.0000");
    die qq{Invalid mac ($mac)} if (length($mac) != 14);
    $mac = prettyMAC($mac);
    if (not defined $ip2mac{$ip}) {
      $ip2mac{$ip} = $mac;
    } else {
      die qq{IP ($ip) defined twice ($ip2mac{$ip} and $mac)}
        unless ($ip2mac{$ip} == $mac);
    }
  }
  return %ip2mac;
}

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

sub cleanMAC($) {
  my $MAC = uc shift;
  $MAC =~ tr/[0-9][A-F]//cd;
  return $MAC;
}

sub prettyMAC($) {
  return sprintf("%02s:%02s:%02s:%02s:%02s:%02s",
           unpack("A2A2A2A2A2A2",
             cleanMAC(shift)
           )
         );
}

sub cleanIP($) {
  my $IP = shift;
  $IP =~ tr/[0-9]\.//cd;
  return $IP
}

sub sortableIP($) {
  return sprintf("%3d.%3d.%3d.%3d", split(/\./, cleanIP(shift)));
}

#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
#### Main
#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####

print qq{Loading current arp table.\n} if defined $DEBUG;
%Arp = GetCurrentInfo(@ROUTERS);

print qq{Comparing current entries to previous entries.\n} if defined $DEBUG;
foreach $ip (sort keys %Arp) {
  print cleanIP($ip) . "\t" . prettyMAC($Arp{$ip}) . "\n";
}
