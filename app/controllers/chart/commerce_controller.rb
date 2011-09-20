class Chart::CommerceController < HighchartsController
  
  def buy_clicks
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => params[:non_cumulative]!='true',
      :whole_history => true,
      :humanize_unknown_series => false,
      :queries_to_fetch => %w(album.buy.toolbar.click photo.buy.toolbar.click photo.buy.frame.click photo.buy.comment.click),
      :series_calculations => [
        {:name => 'photos.buy.click', :op => :sum, :series => %w(photo.buy.toolbar.click photo.buy.frame.click photo.buy.comment.click)}
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
            :text => 'Number of Buy Clicks for Albums and Photos'
          },
          :subtitle => {
            :text => data_src.chart_subtitle
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
              :text => '# of clicks'
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
  
  def buy_clicks_perc
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => params[:non_cumulative]!='true',
      :period => (DateTime.civil(2011, 8, 24)..DateTime.now),
      :humanize_unknown_series => false,
      :queries_to_fetch => %w(album.buy.toolbar.click photo.buy.toolbar.click photo.buy.frame.click photo.buy.comment.click photos.all albums.all),
      :series_calculations => [
        {:name => 'photos.buy.click', :op => :sum, :series => %w(photo.buy.toolbar.click photo.buy.frame.click photo.buy.comment.click)},
        {:name => 'Buy photos', :op => :div, :series => %w(photos.buy.click photos.all)},
        {:name => 'Buy albums', :op => :div, :series => %w(album.buy.toolbar.click albums.all)},
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
            :text => '% of Buy Clicks to Total Albums and Photos'
          },
          :subtitle => {
            :text => data_src.chart_subtitle
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
              :text => '% of clicked'
            },
            :min => 0.0,
            :labels => {:formatter => nil}
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def buy_photo_clicks
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => params[:non_cumulative]!='true',
      :whole_history => true,
      :humanize_unknown_series => false,
      :queries_to_fetch => %w(photo.buy.toolbar.click photo.buy.frame.click photo.buy.comment.click)
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
            :text => '% of Buy Clicks for Photos (toolbar/frame/comment)'
          },
          :subtitle => {
            :text => data_src.chart_subtitle
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
              :text => '# of clicks'
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


end
