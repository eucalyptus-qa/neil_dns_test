#!/usr/bin/perl
use strict;
use Cwd;

$ENV{'PWD'} = getcwd();

if( $ENV{'TEST_DIR'} eq "" ){
        my $cwd = getcwd();
        if( $cwd =~ /^(.+)\/lib/ ){
                $ENV{'TEST_DIR'} = $1;
        }else{
                print "ERROR !! Incorrect Current Working Directory ! \n";
                exit(1);
        };
};


# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};



#################### APP SPECIFIC PACKAGES INSTALLATION ##########################

my @ip_lst;
my @distro_lst;
my @source_lst;
my @roll_lst;

my %cc_lst;
my %sc_lst;
my %nc_lst;

my $clc_index = -1;
my $cc_index = -1;
my $sc_index = -1;
my $ws_index = -1;

my $clc_ip = "";
my $cc_ip = "";
my $sc_ip = "";
my $ws_ip = "";

my $nc_ip = "";

my $max_cc_num = 0;

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

my $bzr_branch = "main-equallogic";
my $arch = "64";

my $script_2_use = "iscsidev-ubuntu.sh";

#### read the input list

my $index = 0;

open( LIST, "../input/2b_tested.lst" ) or die "$!";
my $line;
while( $line = <LIST> ){
	chomp($line);
	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[([\w\s\d]+)\]/ ){
		print "IP $1 with $2 distro will be built from $5 as Eucalyptus-$6\n";
		push( @ip_lst, $1 );
		push( @distro_lst, $2 );
		push( @source_lst, $5 );
		push( @roll_lst, $6 );

		my $this_roll = $6;

		if( does_It_Have($this_roll, "CLC") ){
			$clc_index = $index;
			$clc_ip = $1;
		};

		if( does_It_Have($this_roll, "CC") ){
			$cc_index = $index;
			$cc_ip = $1;

			if( $this_roll =~ /CC(\d+)/ ){
				$cc_lst{"CC_$1"} = $cc_ip;
				if( $1 > $max_cc_num ){
					$max_cc_num = $1;
				};
			};			
		};

		if( does_It_Have($this_roll, "SC") ){
			$sc_index = $index;
			$sc_ip = $1;

			if( $this_roll =~ /SC(\d+)/ ){
                                $sc_lst{"SC_$1"} = $sc_ip;
                        };
		};

		if( does_It_Have($this_roll, "WS") ){
                        $ws_index = $index;
                        $ws_ip = $1;
                };

		if( does_It_Have($this_roll, "NC") ){
                        #$nc_ip = $nc_ip . " " . $1;
			$nc_ip = $1;
			if( $this_roll =~ /NC(\d+)/ ){
				if( $nc_lst{"NC_$1"} eq	 "" ){
                                	$nc_lst{"NC_$1"} = $nc_ip;
				}else{
					$nc_lst{"NC_$1"} = $nc_lst{"NC_$1"} . " " . $nc_ip;
				};
                        };
                };

		$index++;
        }elsif( $line =~ /^BZR_BRANCH\s+(.+)/ ){
		$line = $1;
		if( $line =~ /\/eucalyptus\/(.+)/ ){
			$bzr_branch = $1;
		};
	}elsif( $line =~ /^ARCH\s+(.+)/ ){
		$arch = $1;
	};
};

close( LIST );

if( $clc_ip eq "" ){
	print "Could not find the IP of CLC\n";
};

if( $cc_ip eq "" ){
        print "Could not find the IP of CC\n";
};

if( $sc_ip eq "" ){
        print "Could not find the IP of SC\n";
};

if( $ws_ip eq "" ){
        print "Could not find the IP of WS\n";
};

if( $nc_ip eq "" ){
        print "Could not find the IP of NC\n";
};

chomp($nc_ip);


for( my $i = 0; $i < @ip_lst; $i++ ){
	my $this_ip = $ip_lst[$i];
	my $this_distro = $distro_lst[$i];
	my $this_source = $source_lst[$i];
	my $this_roll = $roll_lst[$i];
	my $stripped_roll = strip_num($this_roll);

	if( does_It_Have($stripped_roll, "CLC") ){
		print "$this_ip : Setting up DNS on this Cloud-Controller\n";

		if( $this_source eq "PACKAGE" || $this_source eq "REPO" ){
                        $ENV{'EUCALYPTUS'} = "";
                };

		# mod disable_dns in eucalyptus.conf
		print("ssh -o StrictHostKeyChecking=no root\@$this_ip \"sed --in-place 's/DISABLE_DNS=\\\"Y\"/DISABLE_DNS=\\\"N\\\"/' $ENV{'EUCALYPTUS'}/etc/eucalyptus/eucalyptus.conf \"\n");
		system("ssh -o StrictHostKeyChecking=no root\@$this_ip \"sed --in-place 's/DISABLE_DNS=\\\"Y\\\"/DISABLE_DNS=\\\"N\\\"/' $ENV{'EUCALYPTUS'}/etc/eucalyptus/eucalyptus.conf \" ");

		# killall dnsmasq
		print("ssh -o StrictHostKeyChecking=no root\@$this_ip \"killall dnsmasq \"\n");
		system("ssh -o StrictHostKeyChecking=no root\@$this_ip \"killall dnsmasq \" ");

		sleep(30);

		# restart cloud
		print("ssh -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud restart \"\n");
		system("ssh -o StrictHostKeyChecking=no root\@$this_ip \"$ENV{'EUCALYPTUS'}/etc/init.d/eucalyptus-cloud restart \" ");

		sleep(30);

	};

};

sleep(120);

exit(0);


1;


sub strip_num{
        my ($str) = @_;
        $str =~ s/\d//g;
        return $str;
};

