class HighchartsController < ApplicationController

protected

  def set_cohort_intersection_params(chart_datasource, opts = {})
    if chart_datasource.weekly_mode?
      @ticks_count = opts[:weeks_count]
      @tick_name = "Week"
      @distance = @ticks_count.weeks
      chart_datasource.category_formatter = Proc.new do |cohort_num, week_start_date|
          cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
          week_begins = Date.parse(week_start_date)
          
          week_num = (week_begins - cohort_beginning).abs.to_i/7
          "#{@tick_name} #{week_num+1}"
      end
    else
      @ticks_count = opts[:days_count]
      @tick_name = "Day"
      @distance = @ticks_count.days
      chart_datasource.category_formatter = Proc.new do |cohort_num, original_category|
          cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
          date = Date.parse(original_category)
          day = date - cohort_beginning
          "#{@tick_name} #{day}"
      end
    end
    chart_datasource.categories = (1..@ticks_count).map{|i| "#{@tick_name} #{i}"}
  end

  def send_xls(datasource, series = nil)
    send_data datasource.produce_xls(series), :content_type => Mime::XLS, :filename => "#{params[:action]}_#{datasource.span_code}_#{DateTime.now.strftime('%Y%m%d%H%M')}.xls"
  end


  def trim_empty_edges!(datasource)
    deletion_positions = []
    indexes = (0..datasource.categories.size-1).to_a
    [indexes, indexes.reverse].each do |range|
      range.each do |i|
        do_cut = !datasource.chart_series.map{|s| s[:data][i] }.any?
        deletion_positions << i if do_cut
        break unless do_cut
      end
    end
    deletion_positions.each do |idx|
      datasource.categories.delete_at(idx)
      datasource.chart_series.each do |serie|
        serie[:data].delete_at(idx)
      end
    end
    deletion_positions.size
  end

end
