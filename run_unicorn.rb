app_dir = Dir.pwd

def do_cmd(cmd)
  puts cmd
  Kernel.system(cmd)
end

do_cmd "unicorn -E production -c #{app_dir}/config/unicorn.rb -D #{app_dir}/config.ru"
