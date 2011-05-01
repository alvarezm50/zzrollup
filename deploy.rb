#!/usr/bin/env ruby

#
# This script does a deploy on the machine that it is run from
# gits the latest code, and hot restarts the server
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

puts "Deploy the rollup server with the latest code from git."
confirm_continue

# hot restart or first time start unicorn
do_cmd "git pull"
do_cmd "run_unicorn.rb"

