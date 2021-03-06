class Chart::LikesController < HighchartsController

  def photos_albums_trend
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :colorize => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.photo.like albums.all photos.all users.all like.user.like),
      :series_calculations => [
        {:name => 'Total Photos', :op => :div, :series => %w(like.photo.like photos.all), :type => :photo},
        {:name => 'Total Albums', :op => :div, :series => %w(like.album.like albums.all), :type => :album},
        {:name => 'Total Users', :op => :div, :series => %w(like.user.like users.all), :type => :user}
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
            :text => 'Percent of Photos, Albums, or Users Liked'
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
              :text => '% of Total Photos/Albums/Users Liked'
            },
            :min => 0,
            :labels => {:formatter => nil}
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
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def likes_by_type
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :colorize => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.photo.like like.user.like)
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
            :defaultSeriesType => 'column'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Number of Photos, Albums, or Users Liked'
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
              :text => '# of Likes'
            },
            :min => 0,
            :labels => {:formatter => nil}
          },
          :plotOptions => {
            :column => {
              :stacking => 'normal'
            }
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def unlikes_by_category
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :colorize => true,
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      #:period => (2.weeks.ago..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.album.unlike like.photo.like	like.photo.unlike like.user.like like.user.unlike),
      :series_calculations => [
        {:name => 'Albums Unliked', :op => :div, :series => %w(like.album.unlike like.album.like), :type => :album},
        {:name => 'Photos Unliked', :op => :div, :series => %w(like.photo.unlike like.photo.like), :type => :photo},
        {:name => 'Users Unliked', :op => :div, :series => %w(like.user.unlike like.user.like), :type => :user}
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
            :text => '% of Photos, Albums, or Users Unliked'
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
              :text => 'Total # Unlikes/Total # Likes'
            },
            :min => 0,
            :max => 1,
            :labels => {:formatter => nil}
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def likes_by_type_trend
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :colorize => true,
      :cumulative => false,
      :emarginate => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.photo.like like.user.like)
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
            :text => 'Number of Photos, Albums, or Users Liked'
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
              :text => "# of Likes#{data_src.weekly_mode? ? ' (average per week)' : ''}"
            },
            :min => 0
          }
        }
      end
    end
  end

  def likes_by_type_perc_trend
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => false,
      :percent_view => true,
      :colorize => true,
      :emarginate => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.photo.like like.user.like albums.all photos.all),
      :series_calculations => [
        {:name => 'Photos', :op => :div, :series => %w(like.photo.like photos.all), :type => :photo},
        {:name => 'Albums', :op => :div, :series => %w(like.album.like albums.all), :type => :album},
        {:name => 'Users', :op => :div, :series => %w(like.user.like albums.all), :type => :user}
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
            :text => '% of Photos, Albums, or Users Liked'
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
              :text => "% of Likes#{data_src.weekly_mode? ? ' (average per week)' : ''}"
            },
            :min => 0,
            :labels => {:formatter => nil}
          },
          :tooltip => {:formatter => nil}
        }
      end
    end
  end

  def unlikes_by_type_trend
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => true,
      :colorize => true,
      :period => (DateTime.civil(2011, 07, 14)..DateTime.now),
      :queries_to_fetch => %w(like.album.unlike like.photo.unlike like.user.unlike)
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
            :text => 'Number of Photos, Albums, or Users Unliked'
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
              :text => "# of Unlikes#{data_src.weekly_mode? ? ' (average per week)' : ''}"
            },
            :min => 0
          }
        }
      end
    end
  end

end
