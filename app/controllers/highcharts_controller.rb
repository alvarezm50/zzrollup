class HighchartsController < ApplicationController
  include ActionView::Helpers::DateHelper
  before_filter :setup_parameters

protected

  def setup_parameters
    @span = (params[:span] || 1440).to_i
    @span_code = RollupTasks.kind(@span)

    @x_ticks_format = case @span_code
      when 'monthly' then '%b %Y'
      when 'daily', 'weekly' then '%m/%d/%y'
      else '%m/%d/%y %H:%i'
    end

    @period = case @span_code
      when 'monthly' then (6.months.ago..Time.now)
      when 'weekly' then (8.weeks.ago..Time.now)
      when 'daily' then (60.days.ago..Time.now)
      when 'hourly' then (4.days.ago..Time.now)
      when 'half-hourly' then (2.days.ago..Time.now)
      when 'quarter-hourly' then (1.day.ago..Time.now)
      else (30.days.ago..Time.now)
    end
  end

  def chart_subtitle
    "#{@span_code.humanize}, #{distance_of_time_in_words(@period.first, @period.last)}"
  end

  def fetch_and_prepare(query_name_mask, known_categories = nil, &block)
    fields_to_select = [
      "DATE_FORMAT(reported_at, '#{@x_ticks_format}') AS report_date",
      "cohort"
    ]
    fields_to_select << if @span_code == 'weekly'
      "ROUND(AVG(sum_value)) AS value"
    else
      "MAX(sum_value) AS value"
    end
    rollup_data_rows = RollupResult.select(fields_to_select.join(',')).group(:report_date).group(:cohort).where(:reported_at => @period).where("cohort > 0 AND span = ? AND query_name LIKE '#{query_name_mask}'", @span).order(:report_date)

    categories = known_categories || rollup_data_rows.map(&:report_date).uniq
    series = {}
    rollup_data_rows.each do |row|
      unless series[row.cohort]
        series[row.cohort] = categories.inject({}) do |hsh, cat|
          hsh[cat] = nil
          hsh
        end
      end
      series[row.cohort][row.report_date] = row.value
    end
    chart_series = series.map do |cohort, values|
      cohort_beginning_of_month_date = CohortManager.cohort_beginning_date(cohort)
      unless block.nil?
        block.call(categories, cohort_beginning_of_month_date, values)
      else
        {
          :name => cohort_beginning_of_month_date.strftime("Cohort %b '%y"),
          :data => categories.map{|cat| values[cat].nil? ? nil : values[cat].to_i } #This should keep the order
        }
      end
    end
    { :series => chart_series, :categories => categories }
  end

end
