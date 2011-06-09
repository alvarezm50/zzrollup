class HighchartsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_filter :setup_parameters

  def active_users_by_cohort #Charts 1
    chart_cfg = {
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'area'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Cumulative Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => chart_subtitle
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

    data = fetch_and_prepare('Cohort.photos_10.%')
    chart_cfg[:xAxis][:categories] = data[:categories]
    chart_cfg[:series] = data[:series].reverse

    render :json => chart_cfg
  end

  def active_users_percent_by_cohort #Charts 2
    chart_cfg = {
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'line'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Cumulative % Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => chart_subtitle
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
          :text => '% Active Users (Add 10+ Photos/month)'
        },
        :min => 0,
        :labels => { :formatter => nil }
      },
      :tooltip => { :formatter => nil }
    }

    users_data = fetch_and_prepare('Cohort.users.%')
    photos10_data = fetch_and_prepare('Cohort.photos_10.%')
    
    percent_series = photos10_data[:series].enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        val = val.to_f / users_data[:series][cohort][:data][idx]
        val.nan? ? nil : val
      end
      {:name => serie[:name], :data => percent_serie_data}
    end

    chart_cfg[:xAxis][:categories] = photos10_data[:categories]
    chart_cfg[:series] = percent_series.reverse

    render :json => chart_cfg
  end

  def daily_cumulative_registered_users_by_cohort #Charts 3
    chart_cfg = {
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'line'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Daily Cumulative Registered Users by Cohort'
      },
      :subtitle => {
        :text => chart_subtitle
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
            :rotation => -45,
            :align => 'right',
            :y => 7,
            :x => 5
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => 'Active Users (Add 10+ Photos/month)'
        },
      }
    }

    categories = (1..31).map{|day| "Day #{day}"}
    
    series = []
    @x_ticks_format = 'Day %e'
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      @period = (cohort_beginning..cohort_beginning.end_of_month)
      cohort_data = fetch_and_prepare("Cohort.users.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
        {
          :name => cohort_beginning_of_month_date.strftime("Cohort %b '%y"),
          :data => categories.map{|cat| values[cat] ? values[cat].to_i : nil }
        }
      end
      series << (cohort_data[:series].first || {:name => cohort_beginning.strftime("Cohort %b '%y"), :data => Array.new(categories.count) })
    end

    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series

    render :json => chart_cfg
  end


protected

  def setup_parameters
    @span = (params[:span] || 1440).to_i
    @span_code = RollupTasks.kind(@span)

    @x_ticks_format = case @span_code
      when 'monthly' then '%b %Y'
      when 'daily' then '%m/%d/%y'
      else '%m/%d/%y %H:%i'
    end
    @period = case @span_code
      when 'monthly' then (6.months.ago..Time.now)
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

  def fetch_and_prepare(query_name_mask, &block)
    rollup_data_rows = RollupResult.select("DATE_FORMAT(reported_at, '#{@x_ticks_format}') AS report_date, cohort, MAX(sum_value) AS value").group(:report_date).group(:cohort).where(:reported_at => @period).where("cohort > 0 AND span = ? AND query_name LIKE '#{query_name_mask}'", @span).order(:report_date)

    categories = rollup_data_rows.map(&:report_date).uniq
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
          :data => categories.map{|cat| values[cat].to_i } #This should keep the order
        }
      end
    end
    {:series => chart_series, :categories => categories}
  end

end
