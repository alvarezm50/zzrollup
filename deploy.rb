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

# pull the latest code
do_cmd "git fetch && git checkout -f master && git pull"

# install any new gems
do_cmd "bundle install --path ../vendor/bundle --deployment"

# pull the latest code
do_cmd "bundle exec rake db:migrate"

# hot restart or first time start unicorn
do_cmd "run_unicorn.rb"

# update any cron job changes
do_cmd "bash -c 'RAILS_ENV=production bundle exec whenever --update-crontab'"