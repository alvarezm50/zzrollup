class Chart::AddPhotoCohortsController < ApplicationController

  def active_users_by_cohort #Charts 1
    data_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.photos_10.%',
      :span => params[:span] || 1440,
      :calculate_now => true
    )

    render :json => {
      :series => data_src.chart_series.reverse,
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
        :text => data_src.chart_subtitle
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => data_src.categories,
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
  end

  def active_users_percent_by_cohort #Charts 2
    users_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.users.%',
      :span => params[:span] || 1440,
      :calculate_now => true
    )
    photos10_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.photos_10.%',
      :span => params[:span] || 1440,
      :categories => users_src.categories,
      :calculate_now => true
    )

    percent_series = photos10_src.chart_series.enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        perc_val = (val.to_f / users_src.chart_series[cohort][:data][idx]) rescue nil
        (perc_val.nil? || perc_val.nan? || perc_val.infinite?) ? nil : perc_val
      end
      {:name => serie[:name], :data => percent_serie_data}
    end

    render :json => {
      :series => percent_series,
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
        :text => users_src.chart_subtitle
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => users_src.categories,
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
  end

  def cumulative_registered_users_by_cohort #Charts 3
    @days_count = 31
    cohort_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    cohort_src.categories = (1..@days_count).map{|day| "Day #{day}"}
    cohort_src.category_formatter = Proc.new do |cohort_num, original_category|
        cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
        date = Date.parse(original_category)
        day = date - cohort_beginning
        "Day #{day}"
    end
    
    series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@days_count.days.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.users.#{cohort}"
      cohort_src.calculate_chart
      series << cohort_src.chart_series.first if cohort_src.chart_series
    end

    render :json => {
      :series => series,
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
        :text => "First #{@days_count} days"
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => cohort_src.categories,
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
          :text => 'Registered Users'
        },
      }
    }
  end

  def registered_users_by_cohort
    @days_count = 31
    cohort_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    cohort_src.categories = (1..@days_count).map{|day| "Day #{day}"}
    cohort_src.category_formatter = Proc.new do |cohort_num, original_category|
        cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
        date = Date.parse(original_category)
        day = date - cohort_beginning
        "Day #{day}"
    end
    
    series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@days_count.days.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.users.#{cohort}"
      cohort_src.calculate_chart
      series << cohort_src.chart_series.first if cohort_src.chart_series
    end
    
    series.each do |serie|
      data_row = serie[:data]
      calculated_row = []
      data_row.each_index do |i|
        prev_val = i==0 ? 0 : (data_row[i-1] || 0)
        calculated_row << (data_row[i].nil? ? nil : (data_row[i] - prev_val))
      end
      serie[:data] = calculated_row
    end

    render :json => {
      :series => series,
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'line'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Daily Registered Users by Cohort'
      },
      :subtitle => {
        :text => "First #{@days_count} days"
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => cohort_src.categories,
        :tickmarkPlacement => 'on',
        :title => {
          :enabled => false
        },
        :labels => {
          :rotation => -45,
          :align => 'right',
          :x => 5
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => 'Registered Users'
        },
      }
    }
  end

  def cumulative_active_users_by_cohort
    @days_count = 60
    cohort_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    cohort_src.categories = (1..@days_count).map{|day| "Day #{day}"}
    cohort_src.category_formatter = Proc.new do |cohort_num, original_category|
        cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
        date = Date.parse(original_category)
        day = date - cohort_beginning
        "Day #{day}"
    end

    series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@days_count.days.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.photos_10.#{cohort}"
      cohort_src.calculate_chart
      series << cohort_src.chart_series.first if cohort_src.chart_series
    end

    render :json => {
      :series => series,
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'line'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Daily Cumulative Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => "First #{@days_count} days"
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => cohort_src.categories,
        :tickmarkPlacement => 'on',
        :title => {
          :enabled => false
        },
        :labels => {
          :rotation => -45,
          :align => 'right',
          :step => 2
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => 'Active Users'
        },
      }
    }
  end

  def cumulative_active_users_by_cohort_percent
    @days_count = 60
    data_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    data_src.categories = (1..@days_count).map{|day| "Day #{day}"}
    data_src.category_formatter = Proc.new do |cohort_num, original_category|
        cohort_beginning = CohortManager.cohort_beginning_date(cohort_num)
        date = Date.parse(original_category)
        day = date - cohort_beginning
        "Day #{day}"
    end

    users_series = []
    photos10_series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      data_src.period = (cohort_beginning..@days_count.days.since(cohort_beginning))

      data_src.query_name_mask = "Cohort.users.#{cohort}"
      data_src.calculate_chart
      users_series << data_src.chart_series.first if data_src.chart_series
      
      data_src.query_name_mask = "Cohort.photos_10.#{cohort}"
      data_src.calculate_chart
      photos10_series << data_src.chart_series.first if data_src.chart_series
    end


    percent_series = photos10_series.enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        perc_val = (val.to_f / users_series[cohort][:data][idx]) rescue nil
        (perc_val.nil? || perc_val.nan? || perc_val.infinite?) ? nil : perc_val
      end
      {:name => serie[:name], :data => percent_serie_data}
    end

    render :json => {
      :series => percent_series,
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'line'
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Daily Cumulative % Active Users (10+ Photos) by Cohort'
      },
      :subtitle => {
        :text => "First #{@days_count} days"
      },
      :legend => {
        :layout => 'vertical'
      },
      :xAxis => {
        :categories => data_src.categories,
        :tickmarkPlacement => 'on',
        :title => {
          :enabled => false
        },
        :labels => {
          :rotation => -45,
          :align => 'right',
          :step => 2
          #:x => 5
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => '% Active Users'
        },
        :labels => { :formatter => nil }
      },
      :tooltip => { :formatter => nil }
    }
  end


end
