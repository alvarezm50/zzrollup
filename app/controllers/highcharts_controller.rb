class HighchartsController < ApplicationController

  def active_users_by_cohort
    span = params[:span] || 1440 #43200 1440
    span_code = RollupTasks.kind(span)

    chart_cfg = {
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
      :legend => {
        :layout => 'vertical'
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
    period = case span_code
      when 'monthly' then (6.months.ago..Time.now)
      when 'daily' then (60.days.ago..Time.now)
      when 'hourly' then (4.days.ago..Time.now)
      when 'half-hourly' then (2.days.ago..Time.now)
      when 'quarter-hourly' then (1.day.ago..Time.now)
      else (30.days.ago..Time.now)
    end

    data = RollupResult.select("DATE_FORMAT(reported_at, '#{x_ticks_format}') AS report_date, cohort, MAX(sum_value) AS value").group(:report_date).group(:cohort).where(:reported_at => period).where('cohort > 0 AND span = ? AND query_name LIKE "Cohort.photos_10.%"', span).order(:report_date)
    
    categories = data.map(&:report_date).uniq
    series = {}
    data.each do |row|
      unless series[row.cohort]
        series[row.cohort] = categories.inject({}) do |hsh, cat|
          hsh[cat] = nil
          hsh
        end
      end
      series[row.cohort][row.report_date] = row.value
    end
    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series.map do |cohort, values|
      cohort_beginning_of_month_date = CohortManager.cohort_base + (cohort - 1).months
      {
        :name => cohort_beginning_of_month_date.strftime("Cohort %b '%y"),
        :data => categories.map{|cat| values[cat].to_i } #This should keep the order
      }
    end.reverse

    render :json => {
      :type => params[:action],
      :config => chart_cfg
    }

  end

end
