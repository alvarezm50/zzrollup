#!/usr/bin/env ruby

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end

app_dir = Dir.pwd

do_cmd "unicorn -E production -c #{app_dir}/config/unicorn.rb -D #{app_dir}/config.ru"
