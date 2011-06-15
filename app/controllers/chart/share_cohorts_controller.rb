class Chart::ShareCohortsController < HighchartsController

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
        :text => 'Cumulative Users that Share (1 Share) by Cohort'
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
          :text => 'Users that Share (1 Share/month)'
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

    data = fetch_and_prepare('Cohort.shares.%')
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
        :text => 'Cumulative % Users that Share (1 Share) by Cohort'
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
          :text => '% of Users that Share (1 Share/month)'
        },
        :min => 0,
        :labels => { :formatter => nil }
      },
      :tooltip => { :formatter => nil }
    }

    users_data = fetch_and_prepare('Cohort.users.%')
    share1_data = fetch_and_prepare('Cohort.shares.%')

    percent_series = share1_data[:series].enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        val = val.to_f / users_data[:series][cohort][:data][idx]
        val.nan? ? nil : val
      end
      {:name => serie[:name], :data => percent_serie_data}
    end

    chart_cfg[:xAxis][:categories] = share1_data[:categories]
    chart_cfg[:series] = percent_series

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
        :text => 'Daily Cumulative Users that Share (1 Share) by Cohort'
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
          :text => 'Users that Share'
        },
      }
    }

    categories = (1..60).map{|day| "Day #{day}"}

    series = []
    @x_ticks_format = '%Y-%m-%e'
    (1..CohortManager.cohort_current).each do |cohort|

      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      @period = (cohort_beginning..60.days.since(cohort_beginning))
      share1_data = fetch_and_prepare("Cohort.shares.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
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
        :data => share1_data[:series].first
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
        :text => 'Daily Cumulative % Users that Share (1 Share) by Cohort'
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
          :text => '% of Users that Share'
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
      share1_data = fetch_and_prepare("Cohort.shares.#{cohort}") do |this_cohort_categories, cohort_beginning_of_month_date, values|
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
        share1_val = share1_data[:series].first[idx]
        percent_data << ((users_val.nil? || share1_val.nil?) ? nil : (share1_val.to_f / users_val.to_f))
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
