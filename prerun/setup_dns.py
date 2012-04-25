#! ../share/python_lib/vic-dev/bin/python

from eucaops import Eucaops


if __name__ == "__main__":
    tester = Eucaops(config_file = "../input/2b_tested.lst", password = "foobar")
    if not tester.clc.found(". eucarc && " + tester.eucapath + "/usr/sbin/euca-modify-property -p system.dns.dnsdomain=localhost", "was"):
        tester.fail("Unable to set use dns subdomain")
    
    if not tester.clc.found(". eucarc && " + tester.eucapath + "/usr/sbin/euca-modify-property -p bootstrap.webservices.use_instance_dns=true", "was"):
        tester.fail("Unable to set use instance_dns")
    tester.do_exit()