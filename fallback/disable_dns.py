#! ../share/python_lib/vic-dev/bin/python

from eucaops import Eucaops


if __name__ == "__main__":
    tester = Eucaops(config_file = "../input/2b_tested.lst", password = "foobar")
    if not tester.found(". eucarc && " + tester.eucapath + "/usr/sbin/euca-modify-property -p bootstrap.webservices.use_instance_dns=false", "was"):
        tester.fail("Unable to reset use instance_dns")

    if not tester.found(". eucarc && " + tester.eucapath + "/usr/sbin/euca-modify-property -r system.dns.dnsdomain", "was"):
        tester.fail("Unable to reset dns subdomain")
    
    tester.do_exit()
    