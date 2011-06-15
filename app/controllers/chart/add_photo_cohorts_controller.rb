class Chart::AddPhotoCohortsController < HighchartsController

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
    chart_cfg[:series] = percent_series

    render :json => chart_cfg
  end

  def cumulative_registered_users_by_cohort #Charts 3
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
        :text => "First 31 days"
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
          :text => 'Registered Users'
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
      series << cohort_data[:series].first if cohort_data[:series].first
    end

    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series

    render :json => chart_cfg
  end

  def registered_users_by_cohort
    chart_cfg = {
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
        :text => "First 31 days"
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

    categories = (1..31).map{|day| "Day #{day}"}

    series = []
    @x_ticks_format = 'Day %e'
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      @period = (cohort_beginning..cohort_beginning.end_of_month)
      cohort_data = fetch_and_prepare("Cohort.users.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
        data_row = categories.map{|cat| values[cat] ? values[cat].to_i : nil }
        calculated_row = []
        data_row.each_index do |i|
          prev_val = i==0 ? 0 : (data_row[i-1] || 0)
          calculated_row << (data_row[i].nil? ? nil : (data_row[i] - prev_val))
        end
        {
          :name => cohort_beginning_of_month_date.strftime("Cohort %b '%y"),
          :data => calculated_row
        }
      end
      series << cohort_data[:series].first if cohort_data[:series].first
    end

    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series

    render :json => chart_cfg
  end

  def cumulative_active_users_by_cohort
    chart_cfg = {
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
        :text => "First 60 days"
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
          :step => 2
          #:x => 5
        }
      },
      :yAxis => {
        :min => 0,
        :title => {
          :text => 'Active Users'
        },
      }
    }

    categories = (1..60).map{|day| "Day #{day}"}

    series = []
    @x_ticks_format = '%Y-%m-%e'
    (1..CohortManager.cohort_current).each do |cohort|

      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      @period = (cohort_beginning..60.days.since(cohort_beginning))
      photos10_data = fetch_and_prepare("Cohort.photos_10.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
        mapping = this_cohort_categories.inject({}) do |hsh, date_str|
          date = Date.parse(date_str)
          day = date - cohort_beginning
          hsh["Day #{day}"] = date_str
          hsh
        end
        categories.map{|cat| values[mapping[cat]] ? values[mapping[cat]].to_i : nil }
      end

      series << {
        :name => cohort_beginning.strftime("Cohort %b '%y"),
        :data => photos10_data[:series].first
      }
    end

    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series

    render :json => chart_cfg
  end

  def cumulative_active_users_by_cohort_percent
    chart_cfg = {
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
        :text => "First 60 days"
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

    categories = (1..60).map{|day| "Day #{day}"}

    series = []
    @x_ticks_format = '%Y-%m-%e'
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      @period = (cohort_beginning..60.days.since(cohort_beginning))
      users_data = fetch_and_prepare("Cohort.users.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
        mapping = this_cohort_categories.inject({}) do |hsh, date_str|
          date = Date.parse(date_str)
          day = date - cohort_beginning
          hsh["Day #{day}"] = date_str
          hsh
        end
        categories.map{|cat| values[mapping[cat]] ? values[mapping[cat]].to_i : nil }
      end
      photos10_data = fetch_and_prepare("Cohort.photos_10.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
        mapping = this_cohort_categories.inject({}) do |hsh, date_str|
          date = Date.parse(date_str)
          day = date - cohort_beginning
          hsh["Day #{day}"] = date_str
          hsh
        end
        categories.map{|cat| values[mapping[cat]] ? values[mapping[cat]].to_i : nil }
      end
      percent_data = []
      categories.each_index do |idx|
        users_val = users_data[:series].first[idx]
        photos10_val = photos10_data[:series].first[idx]
        percent_data << ((users_val.nil? || photos10_val.nil?) ? nil : (photos10_val.to_f / users_val.to_f))
      end
      series << {
        :name => cohort_beginning.strftime("Cohort %b '%y"),
        :data => percent_data
      }
    end

    chart_cfg[:xAxis][:categories] = categories
    chart_cfg[:series] = series

    render :json => chart_cfg
  end


end
