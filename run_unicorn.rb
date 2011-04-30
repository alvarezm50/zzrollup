#!/usr/bin/env ruby

# we either restart unicorn if it is running with USR2 or if not running
# we start it

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end

app_dir = Dir.pwd
pid_file = "/var/run/zangzing/unicorn_rollup.pid"

do_cmd "ps -fp `cat #{pid_file}`"
running = $?.exitstatus == 0

if running
  # restart gracefully
  do_cmd "kill -s USR2 `cat #{pid_file}`"
else
  # start from scratch
  do_cmd "unicorn -E production -c #{app_dir}/config/unicorn.rb -D #{app_dir}/config.ru"
end

