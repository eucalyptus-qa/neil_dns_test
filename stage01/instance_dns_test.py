#! ../share/python_lib/stable/bin/python
import unittest
import re
import sys
sys.path.append("../share/python_lib/testcases")
from instancetest import InstanceBasics
from eucaops import Eucaops

class DNS(InstanceBasics):
    def resolve_hostname(self, instance):
        clc_ip = self.tester.get_clc_ip()
        #nslookup = "nslookup " + clc_ip + " +short "
        ns_suffix = " | grep Address | grep -v \"#\" | awk '{print $2}'"
        response = self.tester.sys("nslookup " + instance.public_dns_name  + " " + clc_ip + ns_suffix)
        public_ip = response[0].strip()
        self.assertTrue( len(response) > 0 , "Public DNS from outside the instance did not resolve properly (no output from dig)")
        self.assertTrue( len(self.tester.sys("nslookup " + instance.private_dns_name  + " " + clc_ip + ns_suffix) ) > 0 , "Private DNS from outside the instance did not resolve properly (no output from dig)")
        
        #try:
        #        instance_ssh = Eucaops( hostname=public_ip,  keypath= self.keypath)
        #except Exception, e: 
        #        self.assertTrue(False, "Failure in connecting to instance" + str(e)) 
        ### TODO Need to switch to an image that has nslookup installed        
        #self.assertTrue( len(instance_ssh.sys("nslookup " +  instance.public_dns_name + " " + clc_ip + ns_suffix)  ) > 0, "Public DNS from inside the instance did not resolve properly (no output from dig)")
        #self.assertTrue( len(instance_ssh.sys("nslookup " +  instance.private_dns_name + " " + clc_ip + ns_suffix) ) > 0, "Private DNS from inside the instance did not resolve properly (no output from dig)")

    
    def InstanceDNS(self):
        '''Run instance check for DNS name'''
        if self.reservation is None:
            self.reservation = self.tester.run_instance(keypair=self.keypair.name, group=self.group.name, is_reachable=False)
            self.tester.sleep(10)
        for instance in self.reservation.instances:
            self.tester.debug(str(instance) + " Public IP is " +  instance.ip_address + " Private IP is " + instance.private_ip_address)
            self.tester.debug(str(instance) + " Public DNS name is " +  instance.public_dns_name + " Private DNS name is " +  instance.private_dns_name )
            self.assertTrue(re.search("euca", instance.public_dns_name), "DNS name not present")
            self.assertFalse(re.search("euca-0-0-0-0", instance.public_dns_name), "Hostname was all 0s")
            self.resolve_hostname(instance)
            
        

if __name__ == "__main__":
    if (len(sys.argv) > 1):
        tests = sys.argv[1:]
    else:
        ### Not ready: test3_StopStart
        tests = ["InstanceDNS"]
    for test in tests:
        result = unittest.TextTestRunner(verbosity=2).run(DNS(test))
        if result.wasSuccessful():
            pass
        else:
            exit(1)
        
