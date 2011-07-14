class Chart::AddPhotoCohortsController < HighchartsController

  def active_users_by_cohort #Charts 1
    data_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.photos_10._',
      :span => params[:span] || 1440,
      :calculate_now => true
    )

    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
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
    end

  end

  def active_users_percent_by_cohort #Charts 2
    users_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.users._',
      :span => params[:span] || 1440,
      :calculate_now => true
    )
    photos10_src = HighchartsDatasource.new(
      :query_name_mask => 'Cohort.photos_10._',
      :span => params[:span] || 1440,
      :categories => users_src.categories,
      :calculate_now => true
    )

    percent_series = photos10_src.chart_series.enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        perc_val = (val.to_f / users_src.chart_series[cohort][:data][idx]) rescue nil
        (perc_val.nil? || perc_val.nan? || perc_val.infinite?) ? nil : perc_val
      end
      {:name => serie[:name], :data => percent_serie_data, :color => HighchartsDatasource.cohort_web_color(serie[:beginning_date])}
    end

    respond_to do |wants|
      wants.xls do
        send_xls(users_src, percent_series)
      end
      wants.json do
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
    end
  end

  def cumulative_active_users_by_cohort
    cohort_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    set_cohort_intersection_params(cohort_src, {:days_count => 60, :weeks_count => 10})

    series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@distance.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.photos_10.#{cohort}"
      cohort_src.calculate_chart
      series << cohort_src.chart_series.first if cohort_src.chart_series.first
    end

    respond_to do |wants|
      wants.xls do
        send_xls(cohort_src, series)
      end
      wants.json do
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
            :text => 'Cumulative Active Users (10+ Photos) by Cohort'
          },
          :subtitle => {
            :text => "#{cohort_src.span_code.humanize}#{cohort_src.weekly_mode? ? ' average' : ''}, First #{@ticks_count} #{@tick_name.downcase}s"
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
              :step => (cohort_src.categories.size/30.0).ceil
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
    end
  end

  def cumulative_active_users_by_cohort_percent
    data_src = HighchartsDatasource.new(:span => params[:span] || 1440)
    set_cohort_intersection_params(data_src, {:days_count => 60, :weeks_count => 10})

    users_series = []
    photos10_series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      data_src.period = (cohort_beginning..@distance.since(cohort_beginning))

      data_src.query_name_mask = "Cohort.users.#{cohort}"
      data_src.calculate_chart
      users_series << data_src.chart_series.first if data_src.chart_series.first
      
      data_src.query_name_mask = "Cohort.photos_10.#{cohort}"
      data_src.calculate_chart
      photos10_series << data_src.chart_series.first if data_src.chart_series.first
    end


    percent_series = photos10_series.enum_with_index.map do |serie, cohort|
      percent_serie_data = serie[:data].enum_with_index.map do |val, idx|
        perc_val = (val.to_f / users_series[cohort][:data][idx]) rescue nil
        (perc_val.nil? || perc_val.nan? || perc_val.infinite?) ? nil : perc_val
      end
      { :name => serie[:name], :data => percent_serie_data, :color => HighchartsDatasource.cohort_web_color(serie[:beginning_date]) }
    end

    respond_to do |wants|
      wants.xls do
        send_xls(data_src, percent_series)
      end
      wants.json do
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
            :text => "#{data_src.span_code.humanize}#{data_src.weekly_mode? ? ' average' : ''}, First #{@ticks_count} #{@tick_name.downcase}s"
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
              :step => (data_src.categories.size/30.0).ceil
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
  end


end
