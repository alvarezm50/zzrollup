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

if !pid.empty?
  do_cmd "kill #{pid}"
end


