#!/usr/bin/perl

use Cwd;



system("rm -fr $ENV{'PWD'}/artifacts/*");
system("rm -fr $ENV{'PWD'}/credentials/*");
system("rm -fr $ENV{'PWD'}/status/*");
system("rm -fr $ENV{'PWD'}/etc/bin");

exit(0);


