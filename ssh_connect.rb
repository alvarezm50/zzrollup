#!/usr/bin/env ruby

#
# This script does a deploy on the machine that it is run from
# gits the latest code, and hot restarts the server
#
require 'readline'

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end


do_cmd "ssh -i ~/.ssh/zza-ec2.pem ec2-user@zza.zangzing.com"
