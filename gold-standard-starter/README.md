Malicious Attacker
This Terraform file will build a signal and a request rule that identifies attack requests from known malicious IP's.

The default attack signals as defined as defined here: https://docs.fastly.com/signalsciences/faq/system-tags/#attacks.

As well as the known malicious IP's from SANS, Tor, and SigSci-IP.

The rule should look like this:

![182690226-6d2ce569-f6c3-4483-8e8a-6fbb1a31a842](https://user-images.githubusercontent.com/113071464/210285988-561b7894-e6cc-4362-973d-16452701d1a7.png)
