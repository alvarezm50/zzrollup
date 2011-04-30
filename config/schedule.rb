require 'config/initializers/zangzing_config'

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# On the production box to set up the schedule run:
# RAILS_ENV=production whenever --update-crontab
#
zc = ::ZangZingConfig.config

env :MAILTO, ''
env :TZ, 'US/Pacific'

set :output, "#{Dir.pwd}/log/cron.log"
set :environment, safe_rails_env
#

every 1.day, :at => '4:38 am' do
  runner "RollupTasks.daily_full_report_sweep"
end

# just for short term testing
#every 1.minute do
#   runner "RollupTasks.daily_full_report_sweep"
#end

# Learn more: http://github.com/javan/whenever
