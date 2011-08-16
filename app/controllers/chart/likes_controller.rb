class Chart::LikesController < HighchartsController

  def photos_albums_trend
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.photo.like albums.all photos.all),
      :series_calculations => [
        {:name => 'Total Photos', :op => :div, :series => %w(like.photo.like photos.all)},
        {:name => 'Total Albums', :op => :div, :series => %w(like.album.like albums.all)}
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
            :text => 'Percent of Photos or Albums Liked'
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
              :text => '% of Photos/Albums'
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

  def total_users
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(users.all like.user.like),
      :series_calculations => [
        {:name => '% of Users', :op => :div, :series => %w(like.user.like users.all)}
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
            :text => 'Percent of Total Users Liked'
          },
          :legend => {:enabled => false},
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
              :text => '% of Users'
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
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
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
            :text => 'Total Likes by Type'
          },
          :subtitle => {
            :text => '# of Photo/Album/User'
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
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      #:period => (2.weeks.ago..DateTime.now),
      :queries_to_fetch => %w(like.album.like like.album.unlike like.photo.like	like.photo.unlike like.user.like like.user.unlike),
      :series_calculations => [
        {:name => 'Albums Unliked', :op => :div, :series => %w(like.album.unlike like.album.like)},
        {:name => 'Photos Unliked', :op => :div, :series => %w(like.photo.unlike like.photo.like)},
        {:name => 'Users Unliked', :op => :div, :series => %w(like.user.unlike like.user.like)}
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
            :defaultSeriesType => 'column'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => '% of Unlikes by Category'
          },
          :subtitle => {
            :text => 'Total Unlikes/Total Likes'
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
              :text => '# of Unlikes'
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

end
