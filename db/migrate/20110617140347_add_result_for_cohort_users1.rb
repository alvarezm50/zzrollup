class AddResultForCohortUsers1 < ActiveRecord::Migration
  def self.up

    # https://zangzing.lighthouseapp.com/projects/52486/tickets/2267-for-daily-cumulative-registered-users-by-cohort-chart-hardcode-the-value-2212-for-days-30-and-31-for-the-april-cohort
    # For "Daily Cumulative Registered Users by Cohort" chart, hardcode the value 2,212 for Days 30 and 31 for the April Cohort.

    RollupResult.create(
      :reported_at => DateTime.parse('2011-04-30 06:55:04 +0000'),
      :span => RollupTasks::DAILY_REPORT_INTERVAL,
      :query_name => 'Cohort.users.1',
      :cohort => 1,
      :sum_value => 2212
    )
    RollupResult.create(
      :reported_at => DateTime.parse('2011-05-01 06:55:04 +0000'),
      :span => RollupTasks::DAILY_REPORT_INTERVAL,
      :query_name => 'Cohort.users.1',
      :cohort => 1,
      :sum_value => 2212
    )
  end

  def self.down
    #I guess there's no reason to delete those missing entries
  end
end
