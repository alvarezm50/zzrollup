class Chart::EmailBreakdownController < HighchartsController

  def raw_stats
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :queries_to_fetch => %w(email.albumshared.send	email.albumshared.click	email.albumshared.open	email.albumshared.bounce)
    )

    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
        render :json => {
          :series => data_src.chart_series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Album Shared: Raw Statistics'
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
              :x => 4,
              :step => (data_src.categories.size/30.0).ceil
            }
          },
          :yAxis => {
            :title => {
              :text => 'Number of Occurences'
            },
            :min => 0
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

  def full_stats
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :queries_to_fetch => %w(email.albumshared.album_grid_url.click	email.albumshared.send	email.albumshared.click	email.albumshared.open	email.albumshared.bounce),
      :series_calculations => [
        {:name => 'Open', :op => :div, :series => %w(email.albumshared.open email.albumshared.send)},
        {:name => 'Click', :op => :div, :series => %w(email.albumshared.click email.albumshared.send)},
        {:name => 'Link', :op => :div, :series => %w(email.albumshared.album_grid_url.click email.albumshared.send)},
        {:name => 'Bounce', :op => :div, :series => %w(email.albumshared.bounce email.albumshared.send)},
      ]
    )

    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
        render :json => {
          :series => data_src.chart_series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Album Shared: Statistics'
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
              :x => 4,
              :step => (data_src.categories.size/30.0).ceil
            }
          },
          :yAxis => {
            :title => {
              :text => '% of Sent'
            },
            :min => 0.0,
            :labels => {:formatter => nil}
          },
          :tooltip => {:formatter => nil},
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


  def link_breakdown
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :period => (DateTime.civil(2011, 07, 20)..DateTime.now),
      :percent_view => true,
      :queries_to_fetch => %w(email.albumshared.album_grid_url.click email.albumshared.click),
      :series_calculations => [
        {:name => '% Clicked', :op => :div, :series => %w(email.albumshared.album_grid_url.click email.albumshared.click)},
      ]
    )

    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
        render :json => {
          :series => data_src.chart_series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Link Breakdown'
          },
          :subtitle => {
            :text => '% that clicked link'
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
              :x => 4,
              :step => (data_src.categories.size/30.0).ceil
            }
          },
          :yAxis => {
            :title => {
              :text => nil
            },
            :min => 0,
            :labels => {:formatter => nil}
          },
          :tooltip => {:formatter => nil},
          :legend => {:enabled => false},
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


end
