current_path = '/home/ec2-user/rails/rollup'
current_path = './'

working_directory current_path
worker_processes 3
listen '/var/run/zangzing/unicorn_rollup.sock', :backlog => 1024
timeout 60
pid "/var/run/zangzing/unicorn_rollup.pid"

# Based on http://gist.github.com/206253

logger Logger.new("log/unicorn.log")

# Load the app into the master before forking workers for super-fast worker spawn times
preload_app true

# some applications/frameworks log to stderr or stdout, so prevent
# them from going to /dev/null when daemonized here:
stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"

# REE - http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

before_fork do |server, worker|

  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.
  old_pid = File.read("#{server.config[:pid]}.oldbin").to_i rescue 0
  server_pid = File.read("#{server.config[:pid]}").to_i rescue 0
  puts "In Before fork, old_pid: #{old_pid}, server_pid: #{server_pid}"

  if old_pid != 0 && server_pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :TERM : :TTOU
      puts "Sending to old: #{old_pid}: #{sig}, worker.nr: #{worker.nr}, server.worker_processes: #{server.worker_processes}"
      Process.kill(sig, old_pid)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
  sleep 1
end

after_fork do |server, worker|
  worker_pid = File.join(File.dirname(server.config[:pid]), "unicorn_worker_rollup_#{worker.nr}.pid")
  puts "In After fork: #{worker_pid}"
  File.open(worker_pid, "w") { |f| f.puts Process.pid }
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    PhotoDB.establish_connection
    RollupDB.establish_connection
    ZZADB.establish_connection
  end
end
