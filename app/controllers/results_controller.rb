class ResultsController < ApplicationController
  before_filter :authenticate

  def daily_report_file
    span = RollupTasks::DAILY_REPORT_INTERVAL
    base_file_name = "rollup-#{RollupTasks.kind(span)}"

    zip_it = false
    t = RollupTasks.create_csv(span, zip_it, base_file_name)

    # send it
    if zip_it
      send_file t.path, :type => 'application/zip', :filename => "#{base_file_name}.zip"
    else
      send_file t.path, :type => 'text/csv', :filename => "#{base_file_name}.csv"
    end
  end

  def daily_report_table
    span = RollupTasks::DAILY_REPORT_INTERVAL

    @rollup_data = RollupTasks.rollup_raw_data(span)

    if @rollup_data.empty?
      render :nothing => true
    else
      render :action => "results_daily_report", :layout => "basic"
    end
  end
end