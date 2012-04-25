#!/usr/bin/perl

require "ec2ops.pl";

use URI;

$EC2 = "euca";

$ec2timeout = 30;

sub failure {
  my($msg) = @_;
  print "[TEST_REPORT]\tFAILED: ", $msg, "\n";
  exit(1);
}

sub success {
  my($msg) = @_;
  print "[TEST_REPORT]\t", $msg, "\n";
}

$mode = shift @ARGV;

if( $mode eq "" ){
        my $this_mode = `cat ../input/2b_tested.lst | grep NETWORK`;
        chomp($this_mode);
        if( $this_mode =~ /^NETWORK\s+(\S+)/ ){
                $mode = lc($1);
        };
};

print "Mode:\t$mode \n\n";

if ($mode eq "system" || $mode eq "static") {
    $managed = 0;
} else {
    $managed = 1;
}

parse_input();
print "SUCCESS: parsed input\n";

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

$rc = getproperty('bootstrap.webservices.use_instance_dns');
if (!$rc) {
    print "SUCCESS: get property $current_artifacts{'systemproperty'}\n";
    setproperties('bootstrap.webservices.use_instance_dns', 'true');
    print "SUCCESS: set property bootstrap.webservices.use_instance_dns to true\n";
} else {
    print "No property found: bootstrap.webservices.use_instance_dns\n";
}

# get the emis
system("date");
$cmd = "runat $ec2timeout $EC2-describe-images -a";
$count=0;
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    my ($type, $id, @tmp) = split(/\s+/, $line);
    if ($id =~ /^emi/) {
	$emis[$count] = $id;
	$count++;
    }
}
close(RFH);
if (@emis < 1) {
    print "ERROR: could not get emis from $EC2-describe-images\n";
    exit(1);
}

#choose one at random
$theemi = $emis[int(rand(@emis))];

#choose number to run
#$numinsts = int(rand(2)) + 1;    
$numinsts=1;

#choose ssh key
$count=0;
system("date");
$cmd = "runat $ec2timeout $EC2-describe-keypairs";
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    my ($tmp, $kp) = split(/\s+/, $line);
    if ($kp) {
	$kps[$count] = $kp;
	$count++;
    }
}
close(RFH);
if (@kps < 1) {
    print "ERROR: could not get keypairs from $EC2-describe-keypairs\n";
    exit(1);
}

#$kp = $kps[int(rand(@kps))];

$kp = $kps[0];
$thekey = "$kp";

if ($managed) {
#choose public address
$count=0;
system("date");
$cmd = "runat $ec2timeout $EC2-describe-addresses | grep admin";
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    my ($tmp, $ip) = split(/\s+/, $line);
    if ($ip) {
	$ips[$count] = $ip;
	$count++;
    }
}
close(RFH);
if (@ips < 1) {
    print "ERROR: could not get addrs from $EC2-describe-addresses\n";
    exit(1);
}
#choose ip at random
$theip = $ips[int(rand(@ips))];
} else {
    
}

#choose public address
$count=0;
system("date");
$cmd = "runat $ec2timeout $EC2-describe-groups";
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    my ($type, $meh, $group) = split(/\s+/, $line);
    if ($type eq "GROUP") {
	if ($group && $group ne "default") {
	    $groups[$count] = $group;
	    $count++;
	}
    }
}
close(RFH);
if (@groups < 1) {
    print "ERROR: could not get groups from $EC2-describe-groups\n";
    exit(1);
}
#choose group at random
$thegroup = $groups[int(rand(@groups))];
#$thegroup = "default";
print "EMI:$theemi KEY:$thekey GROUP:$thegroup NUMINST:$numinsts\n";

#ready to run

$done=$runcount=0;
while(!$done && $runcount < 1) {
    system("date");
$cmd = "runat $ec2timeout $EC2-run-instances $theemi -k $thekey -n $numinsts -g $thegroup";
    $count=0;
    open(RFH, "$cmd|");
    while(<RFH>) {
	chomp;
	my $line = $_;
	print "OUTPUT: $line\n";
	my ($type, $id, $emi, $publicip, $privateip, $state, @tmp) = split(/\s+/, $line);
	if ($type eq "INSTANCE") {
	    $ids[$count] = $id;
	    $count++;
	}
    }
    close(RFH);
    $runcount++;
    $numrunnin = @ids;
    print "STARTED:@ids, $numrunnin, $numinsts\n";
    if ($numrunnin != $numinsts) {
	$n = @ids;
	print "not enough resources yet (or timeout), retrying\n";
    } else {
	$done++;
    }
}

if (!$done) {
    print "ERROR: could not start target number of insts (target/actual): $numinsts/@n\n";
    exit(1);
}

$count=20;
$done=0;
while(!$done && $count > 0) {
system("date");
$cmd = "runat $ec2timeout $EC2-describe-instances";
#$count=0;
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    print "DESCRIBE INSTANCES: $line\n";
    my ($type, $id, $emi, $ip0, $ip1, $status, @tmp) = split(/\s+/, $line);
    if ($type eq "INSTANCE" && $status eq "running" && !($ip0 =~ m/^(euca-0-0-0-0)/i)  ) {
	$done++;
    }
}
$count--;
close(RFH);
sleep(30);
}

#cleanup any terminated instances
system("date");
$cmd = "runat $ec2timeout $EC2-describe-instances";
$count=0;
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    print "OUTPUT: $line\n";
    my ($type, $id, $emi, $ip0, $ip1, $status, @tmp) = split(/\s+/, $line);
    if ($type eq "INSTANCE" && $status eq "terminated") {
      $terminated_ids[$count] = $id;
      $count++;
    }
}
close(RFH);

for $id(@terminated_ids) {
  $cmd = "runat $ec2timeout $EC2-terminate-instances $id";
  open(RFH, "$cmd|");
  while(<RFH>) {
    chomp;
    my $line = $_;
    print "OUTPUT: $line\n";
  }
}

if ($managed) {
#relase public addresses

$count=0;
system("date");
$cmd = "runat $ec2timeout $EC2-describe-addresses | grep admin";
open(RFH, "$cmd|");
while(<RFH>) {
    chomp;
    my $line = $_;
    my ($tmp, $ip) = split(/\s+/, $line);
    if ($ip) {
        $cmd = "runat $ec2timeout $EC2-release-address $ip";
        open(RFH, "$cmd|");
        while(<RFH>) {
        chomp;
        print $_;
        }
    }
    $count++;
    }
close(RFH);

} else {
    
}
sub get_ips{
    $cmd = "runat $ec2timeout $EC2-describe-instances";
    open(RFH, "$cmd|");
    while(<RFH>) {
	chomp;
	my $line = $_;
	print "OUTPUT: $line\n";
	($type, $id, $emi, $publicip, $privateip, @tmp) = split(/\s+/, $line);
  }
  close(RFH);
  failure("Public IP not found") unless defined $publicip;
  failure("Private IP not found") unless defined $privateip;
  return ($publicip, $privateip);
}


sub resolve_hostname{
  my($ec2_host, $hostname) = @_;
  $cmd = "dig \@$ec2_host $hostname";
  open(RFH, "$cmd|");
  $found = 0;
  while(<RFH>) {
    chomp;
    my $line = $_;
    print $_;
    if ($line =~ /^$hostname\./) {
       success ($line);
       $found = 1;
    }
  }
  close(RFH);
  failure("Unable to resolve $hostname") if($found == 0);
}

my $s3_url = URI->new($ENV{'S3_URL'});
$s3_host = $s3_url->host();

failure("Unable to get S3 host. Is S3_URL set?") unless defined $s3_host;

my $ec2_url = URI->new($ENV{'EC2_URL'});
$ec2_host = $ec2_url->host();

failure("Unable to get EC2_URL host. Is EC2_URL set?") unless defined $ec2_host;


$s3curl_home = $ENV{'S3_CURL_HOME'};
$id = $ENV{'EC2_ACCESS_KEY'};
$key = $ENV{'EC2_SECRET_KEY'};
$s3_url = $ENV{'S3_URL'};

failure("S3_CURL_HOME must be set.") unless defined $s3curl_home;
failure("EC2_ACCESS_KEY must be set.") unless defined $id;
failure("EC2_SECRET_KEY must be set.") unless defined $key;
failure("S3_URL must be set.") unless defined $s3_url;

($public_ip, $private_ip) = get_ips();
resolve_hostname($ec2_host, $public_ip);
resolve_hostname($ec2_host, $private_ip);

$rc = getproperty('bootstrap.webservices.use_instance_dns');
if (!$rc) {
    print "SUCCESS: get property $current_artifacts{'systemproperty'}\n";
    setproperties('bootstrap.webservices.use_instance_dns', 'false');
    print "SUCCESS: set property bootstrap.webservices.use_instance_dns to false\n";
} else {
    print "No property found: bootstrap.webservices.use_instance_dns\n";
}


exit(0);
