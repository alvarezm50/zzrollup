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
job_type :runner, "cd :path && bundle exec script/rails runner -e :environment ':task' :output"

#

# even though TZ is set, time still appear to be in UTC
every 1.day, :at => '6:55 am' do
  runner "RollupTasks.daily_full_report_sweep"
end

# short term stats
every 15.minutes do
   runner "RollupTasks.minimal_sweep"
end

# even though TZ is set, time still appear to be in UTC
# so instead of last day of month we specify first day
# because we then back up our local timezone offset which is
# 7 or 8 hours depending on DST which puts us back on the
# last day of the month - yuck
every '35 6 1 * *' do
  runner "RollupTasks.monthly_sweep"
end


# Learn more: http://github.com/javan/whenever
