class HighchartsController < ApplicationController

  def active_users_by_cohort
    span = params[:span] || 1440 #43200 1440
    span_code = RollupTasks.kind(span)

    f_chart_cfg = {
      :chart => {
        :renderTo => params[:action].gsub('_', '-'),
        :defaultSeriesType => 'area'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Cumulative Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => span_code.humanize
      },
      :xAxis => {
        :tickmarkPlacement => 'on',
        :title => {
          :enabled => false
        },
        :labels => {
            :rotation => -90,
            :align => 'right',
            :y => 3,
            :x => 4
        }
      },
      :yAxis => {
        :title => {
          :text => 'Active Users (Add 10+ Photos/month)'
        },
      },
      :plotOptions => {
        :area => {
          :stacking => 'normal',
          :lineColor => '#666666',
          :lineWidth => 1,
          :marker => {
            :lineWidth => 1,
            :lineColor => '#666666'
          }
        }
      }
    }

    x_ticks_format = case span_code
      when 'monthly' then '%b %Y'
      when 'daily' then '%m/%d/%y'
      else '%m/%d/%y %H:%i'
    end
    period = (60.days.ago..Time.now)

    data = RollupResult.select("DATE_FORMAT(reported_at, '#{x_ticks_format}') AS report_date, cohort, SUM(sum_value) AS value").group(:report_date).group(:cohort).where(:reported_at => period).where('cohort > 0 AND span = ? AND query_name LIKE "Cohort.photos_10%"', span).order(:report_date)
    
    categories = data.map(&:report_date).uniq
    series = {}
    data.each do |row|
      unless series[row.cohort]
        series[row.cohort] = categories.inject({}) do |hsh, cat|
          hsh[cat] = 0
          hsh
        end
      end
      series[row.cohort][row.report_date] = row.value
    end
    f_chart_cfg[:xAxis][:categories] = categories
    f_chart_cfg[:series] = series.map do |cohort, values|
      cohort_beginning_of_month_date = CohortManager.cohort_base + (cohort - 1).months
      {
        :name => cohort_beginning_of_month_date.strftime("Cohort %b '%y"),
        :data => categories.map{|cat| values[cat].to_i } #This should keep the order
      }
    end

    render :json => {
      :type => params[:action],
      :config => f_chart_cfg
    }

  end

end
