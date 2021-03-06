class GeckoController < ApplicationController

  # this is for gathering stats in JSON format for geckoboard
  # you specify as an argument the name of the stat (one of the
  # headers in the rollup report) and an interval of how far
  # back to find the second stat in minutes.  So, if you
  # want to find todays results and yesterdays, you would
  # specify the uri as /gecko_before_after?stat=Albums.all&interval=1440
  #
  # NOTE: the interval is expected to be minutes.  The interval back
  # in time will always perform a reported_at >= (latest - interval) so
  # it finds the nearest match.  For this reason since our rollup results
  # can be off by a few seconds either way, it is probably a good idea
  # pass a time with a couple of extra minutes added.
  #
  def before_after
    stat = params[:stat]
    interval = params[:interval]
    cohort = params[:cohort]
    if stat.nil? || interval.nil?
      render :text => "Missing stat and/or interval.", :status=>500 and return
    end
    interval = interval.to_i

    # if a value is passed for cohort, it is tacked onto the stat name
    # we have a special case for a value of 'current' where we use the
    # current cohort and add that
    if !cohort.nil?
      cohort = cohort == 'current' ? CohortManager.cohort_current : cohort.to_i
      stat = "#{stat}.#{cohort}"
    end

    # first find the latest matching stat
    latest = RollupResult.where("query_name = ?", stat).order("reported_at").last
    if latest.nil?
      render :text => "No results found for #{stat}", :status=>500 and return
    end

    back_to = latest.reported_at - (interval * 60).seconds

    previous = RollupResult.where("query_name = ? AND reported_at >= ?", stat, back_to).order("reported_at").first

    # now build the json result by first placing in a hash
    gecko_result = {
        :item => [
            {:text => latest.reported_at.in_time_zone(RollupTasks::TIME_ZONE).strftime("%Y-%m-%d %I:%M %p"), :value => latest.sum_value},
            {:text => previous.reported_at.in_time_zone(RollupTasks::TIME_ZONE).strftime("%Y-%m-%d %I:%M %p"), :value => previous.sum_value}
        ]
    }
    json_str = JSON.fast_generate(gecko_result)
    render :json => json_str
  end

end