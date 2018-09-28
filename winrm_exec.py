#!/usr/bin/env python

import os
import winrm
import base64
import argparse
import sys

reload(sys)
sys.setdefaultencoding("UTF8")


def get_ps_enc(file_name):
    with open(file_name, 'r') as f:
        ps = "\n" + f.read()

    enc_ps = base64.b64encode(ps.encode("utf-16-le"))
    return enc_ps

def run_ps(file_name, ip_server, x86):
    file_name = os.path.join(os.path.dirname(__file__), file_name)
    enc_ps = get_ps_enc(file_name)
    s = winrm.Session('http://'+ ip_server + ':5985/wsman', auth=('Administrator', 'Passw0rd'))
    if x86:
        r = s.run_cmd('%SystemRoot%\\syswow64\\WindowsPowerShell\\v1.0\\powershell.exe', ["-EncodedCommand", "%s" % enc_ps])
    else:
        r = s.run_cmd("powershell", ["-EncodedCommand", "%s" % enc_ps])

    return r.status_code, r.std_out, r.std_err

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='This is a simple WinRM client.')
    parser.add_argument('ip', metavar='<IP address>',
        help='Server IP address.')
    parser.add_argument('-f', metavar='<powershell file>',
        required=True,
        help='the powershell file to send/execute.')
    parser.add_argument('-x86', help='Switch to x86. Default: amd64', action='store_true')
    parser.add_argument("-v", "--verbose", help="increase output verbosity",
        action="store_true")
    opts = parser.parse_args()

print "- Using file " + opts.f + " on server " + opts.ip
if opts.x86:
    print "- Running 32 bit powershell"
else:
    print "- Running 64 bit powershell"

output = run_ps(opts.f, opts.ip, opts.x86)

if not output[0]:
    print "\n-Status: Script went ok\n"
else:
    print "\n-Status: Something failed\n"

if opts.verbose:
    print "-Script Output: \n ----------------------\n" + output[1] + output[2]

