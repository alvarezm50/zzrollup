#!/usr/bin/env ruby

# this script prepares for a deploy by putting down
# a label across all repositories and optionally
# will create a branch for production fixes off of the master branch
#
#
require 'readline'

def confirm_continue
  print "Do you want to continue? (Yes/n): "
  r = Readline.readline()
  if r != "Yes"
    puts "Exiting. Bye."
    exit
  end
end

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end

release_path = "/home/ec2-user/rails/rollup"

# set up the initial configuration
do_cmd "sudo mkdir -p /var/run/zangzing"
do_cmd "sudo chown ec2-user:ec2-user /var/run/zangzing"

do_cmd "sudo ln -nfs #{release_path}/deploy/rollup.conf /etc/nginx/conf.d/rollup.conf"
do_cmd "sudo ln -nfs #{release_path}/deploy/unicorn_rollup.monitrc /etc/monit.d/unicorn_rollup.monitrc"

do_cmd "sudo monit reload"

do_cmd "sudo monit restart unicorn_rollup"


