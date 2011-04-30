#!/usr/bin/env ruby

# we either restart unicorn if it is running with USR2 or if not running
# we start it

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end

app_dir = Dir.pwd
pid_file = "/var/run/zangzing/unicorn_rollup.pid"

pid = `cat #{pid_file}`
running = false

if !pid.empty?
  do_cmd "ps -fp #{pid}"
  running = $?.exitstatus == 0
end

if running
  # restart gracefully
  do_cmd "kill -s USR2 #{pid}"
else
  # start from scratch
  do_cmd "unicorn -E production -c #{app_dir}/config/unicorn.rb -D #{app_dir}/config.ru"
end

