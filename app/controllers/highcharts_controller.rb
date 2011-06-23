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

end
