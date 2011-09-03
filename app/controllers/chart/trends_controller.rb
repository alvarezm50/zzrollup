class Chart::TrendsController < HighchartsController
  
  def daily_growth
    @entity = case params[:entity]
      when 'photos' then 'photos'
      when 'albums' then 'albums'
    end
    data_src = RollupData::DailyGrowthDatasource.new(:queries_to_fetch => %W(#{@entity}.all), :calculate_now => true)
    
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
            :text => "# of #{@entity.humanize}"
          },
          :subtitle => {
            :text => 'Non-cumulative, Daily for First 30 Days'
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
          }
        }
      end
    end
  end
  
  def photos_per_album_avg
    photos_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => 10080,
      :queries_to_fetch => %w(Photos.all Albums.all),
      :series_calculations => [
        {:name => 'Values', :op => :div, :series => %w(Photos.all Albums.all)},
      ]      
    )

    respond_to do |wants|
      wants.xls do
        send_xls(photos_src)
      end
      wants.json do
        render :json => {
          :series => photos_src.chart_series,
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
            :text => photos_src.chart_subtitle
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

  def totals
    @entity = case params[:entity]
      when 'photos' then 'photos'
      when 'albums' then 'albums'
    end
    albums_src = RollupData::UniversalDatasource.new(
      :span => params[:span],
      :cumulative => params[:non_cumulative]!='true',
      :queries_to_fetch => %W(#{@entity}.all),
      :calculate_now => true
    )

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
            :text => "Total # of #{@entity.humanize}"
          },
          :subtitle => {
            :text => albums_src.chart_subtitle
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
              :text => "Number of #{@entity.humanize}"
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
    data_src = RollupData::DailyGrowthDatasource.new(:queries_to_fetch => %w(Photos.all), :calculate_now => true)

    categories = []
    values = []
    
    data_src.chart_series.reverse.each do |serie|
      categories << serie[:name]
      res_val = serie[:data].compact.inject(0){|s,e| s+e }.to_f / serie[:data].compact.size
      values << (res_val*100).round/100.0
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
            :categories => data_src.categories
          },
          :title => {
            :text => 'Average Photos/Day'
          },
          :subtitle => {
            :text => 'Cumulative, on a monthly basis'
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
