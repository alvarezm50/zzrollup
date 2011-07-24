class Chart::TrendsController < HighchartsController
  
  def daily_growth
    data_src = DailyGrowthDatasource.new(:query_name_mask => 'Photos.all', :calculate_now => true)
    
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
            :text => 'Daily Growth of Photos By Month'
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
              :text => 'Number of Photos'
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
  
  def photos_per_album_avg
    photos_src = TrendsDatasource.new(:query_name_mask => 'Photos.all', :calculate_now => true)
    albums_src = TrendsDatasource.new(:query_name_mask => 'Albums.all', :calculate_now => true)
    
    series = photos_src.chart_series.enum_with_index.map do |serie, i|
      data = serie[:data].enum_with_index.map do |val, idx|
        res_val = (val.to_f / albums_src.chart_series[i][:data][idx]) rescue nil
        (res_val.nil? || res_val.nan? || res_val.infinite?) ? nil : (res_val*100).round/100.0
      end
      {:name => serie[:name], :data => data}
    end

    respond_to do |wants|
      wants.xls do
        send_xls(photos_src, series)
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
            :text => 'Average Photos per Album'
          },
          :subtitle => {
            :text => 'Weekly'
          },
          :legend => {
            :enabled => false
          },
          :xAxis => {
            :categories => photos_src.categories,
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
              :text => 'Average # of Photos'
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

  def total_albums
    albums_src = TrendsDatasource.new(:query_name_mask => 'Albums.all', :calculate_now => true)

    respond_to do |wants|
      wants.xls do
        send_xls(albums_src)
      end
      wants.json do
        render :json => {
          :series => albums_src.chart_series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Total Albums'
          },
          :legend => {
            :enabled => false
          },
          :xAxis => {
            :categories => albums_src.categories,
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
              :text => 'Number of Albums'
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


  def total_photos
    albums_src = TrendsDatasource.new(:query_name_mask => 'Photos.all', :calculate_now => true)

    respond_to do |wants|
      wants.xls do
        send_xls(albums_src)
      end
      wants.json do
        render :json => {
          :series => albums_src.chart_series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Total Photos'
          },
          :legend => {
            :enabled => false
          },
          :xAxis => {
            :categories => albums_src.categories,
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
              :text => 'Number of Photos'
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


  def photos_per_day_monthly
    data_src = DailyGrowthDatasource.new(:query_name_mask => 'Photos.all', :calculate_now => true)

    categories = []
    values = []
    
    data_src.chart_series.reverse.each do |serie|
      categories << serie[:name]
      values << serie[:data].compact.inject(0){|s,e| s+e }
    end
    data_src.categories = categories
    series = [{:name => 'Number', :data => values}]

    respond_to do |wants|
      wants.xls do
        send_xls(data_src, series)
      end
      wants.json do
        render :json => {
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'column'
          },
          :series => series,
          :xAxis => {
            :categories => categories
          },
          :title => {
            :text => 'Average Photos/Day per Month'
          },
          :yAxis => {
            :labels => { :formatter => nil },
            :title => {
              :text => 'Average Photos Per Day'
            },
          },
          :legend => {
            :enabled => false
          },
          :credits => {
            :enabled => false
          }
        }
      end
    end
  end



end
