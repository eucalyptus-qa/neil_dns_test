#!/usr/bin/perl

use URI;

sub failure {
  my($msg) = @_;
  print "[TEST_REPORT]\tFAILED: ", $msg, "\n";
  exit(1);
}

sub success {
  my($msg) = @_;
  print "[TEST_REPORT]\t", $msg, "\n";
}

sub make_bucket {
  my($s3_host, $s3curl_home, $id, $key, $s3_url, $bucket) = @_;
  $cmd = "$s3curl_home/s3curl.pl --endpoint $s3_host --id $id --key $key --put /dev/null $s3_url/$bucket";
  open(RFH, "$cmd|");
  while(<RFH>) {
    print $_;
  }
  close(RFH);
}

sub cleanup_bucket {
  my($s3_host, $s3curl_home, $id, $key, $s3_url, $bucket) = @_;
  $cmd = "$s3curl_home/s3curl.pl --endpoint $s3_host --id $id --key $key --del $s3_url/$bucket";
  open(RFH, "$cmd|");
  while(<RFH>) {
    print $_;
  }
  close(RFH);
}


sub resolve_hostname{
  my($ec2_host, $bucket) = @_;
  $cmd = "dig \@$ec2_host $bucket.walrus.localhost";
  open(RFH, "$cmd|");
  $found = 0;
  while(<RFH>) {
    chomp;
    my $line = $_;
    if ($line =~ /^$bucket\.walrus\.localhost\./) {
       success ($line);
       $found = 1;
    }
  }
  close(RFH);
  failure("Unable to resolve $bucket.walrus.localhost") if($found == 0);
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

make_bucket($s3_host, $s3curl_home, $id, $key, $s3_url, 'testbucket0');
resolve_hostname($ec2_host, 'testbucket0');
cleanup_bucket($s3_host, $s3curl_home, $id, $key, $s3_url, 'testbucket0');
exit(0);
