class Chart::RegisteredUsersController < HighchartsController
  
  def registered_users_cumulative
    data_src = CohortsDatasource.new(
      :query_name_mask => 'Cohort.users._',
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
            :text => 'Cumulative Registered Users'
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
              :text => 'Registered Users'
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


  def cumulative_registered_users_by_cohort #Charts 3
    cohort_src = CohortsDatasource.new(:span => params[:span] || 1440)
    set_cohort_intersection_params(cohort_src, {:days_count => 31, :weeks_count => 6})

    series = []
    (1..CohortManager.cohort_current).to_a.each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@distance.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.users.#{cohort}"
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
            :text => 'Cumulative Registered Users by Cohort'
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
    end
  end

  def registered_users_by_cohort
    cohort_src = CohortsDatasource.new(:span => params[:span] || 1440)
    set_cohort_intersection_params(cohort_src, {:days_count => 31, :weeks_count => 6})

    series = []
    (1..CohortManager.cohort_current).each do |cohort|
      cohort_beginning = CohortManager.cohort_beginning_date(cohort)
      cohort_src.period = (cohort_beginning..@ticks_count.days.since(cohort_beginning))
      cohort_src.query_name_mask = "Cohort.users.#{cohort}"
      cohort_src.calculate_chart
      series << cohort_src.chart_series.first if cohort_src.chart_series.first
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
            :text => 'Registered Users by Cohort'
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
    end
  end


end
