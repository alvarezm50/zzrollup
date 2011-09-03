class Chart::SharesController < HighchartsController

  def total_shared_perc
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :cumulative => params[:non_cumulative]!='true',
      :span => params[:span] || 1440,
      :queries_to_fetch => %w(albums.all photos.all album.share.email album.share.twitter album.share.facebook album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter photo.share.email photo.share.facebook photo.share.twitter),
      :series_calculations => [
        {:name => 'PhotosShared', :op => :sum, :series => %w(photo.share.email photo.share.facebook photo.share.twitter)},
        {:name => 'AlbumsShared', :op => :sum, :series => %w(album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter album.share.email album.share.twitter album.share.facebook)},
        {:name => 'Total Photos', :op => :div, :series => %w(PhotosShared photos.all)},
        {:name => 'Total Albums', :op => :div, :series => %w(AlbumsShared albums.all)}
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
            :text => 'Percentage of Photos or Albums Shared'
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
              :text => '% of Total'
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

  def total_shared
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :cumulative => params[:non_cumulative]!='true',
      :span => params[:span] || 1440,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(album.share.email album.share.twitter album.share.facebook album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter photo.share.email photo.share.facebook photo.share.twitter),
      :series_calculations => [
        {:name => 'Total Photos', :op => :sum, :series => %w(photo.share.email photo.share.facebook photo.share.twitter)},
        {:name => 'Total Albums', :op => :sum, :series => %w(album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter album.share.email album.share.twitter album.share.facebook)}
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
            :text => 'Number of Photos or Albums Shared'
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
              :text => '# Shared'
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


  def shares_by_type
    data_src =RollupData::UniversalDatasource.new(
      :colorize => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => case params[:entity]
        when 'photos' then %w(photo.share.email photo.share.facebook photo.share.twitter)
        when 'albums' then %w(album.share.email album.share.facebook album.share.twitter album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter)
      end
    )
    if params[:entity]=='albums'
      data_src.series_calculations = [
        {:name => 'via Email', :op => :sum, :series => %w(album.share.email album.share.group_tab.email)},
        {:name => 'via Facebook', :op => :sum, :series => %w(album.share.facebook album.share.group_tab.facebook)},
        {:name => 'via Twitter', :op => :sum, :series => %w(album.share.twitter album.share.group_tab.twitter)},
      ]
    end
    data_src.calculate_chart

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
            :text => "Number of #{params[:entity].camelcase} Shared (Email/FB/Twitter)"
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
              :text => "# of #{params[:entity].camelcase} Shared"
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

  def shares_by_type_percent
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :colorize => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(album.share.email album.share.twitter album.share.facebook album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter photo.share.email photo.share.facebook photo.share.twitter),
      :series_calculations => [
        {:name => 'total', :op => :sum, :series => %w(photo.share.email photo.share.facebook photo.share.twitter album.share.email album.share.twitter album.share.facebook album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter)},
        {:name => 'totalEmail', :op => :sum, :series => %w(photo.share.email album.share.email album.share.group_tab.email)},
        {:name => 'totalTwitter', :op => :sum, :series => %w(photo.share.twitter album.share.twitter album.share.group_tab.twitter)},
        {:name => 'totalFacebook', :op => :sum, :series => %w(photo.share.facebook album.share.facebook album.share.group_tab.facebook)},
        {:name => '% Email', :op => :div, :series => %w(totalEmail total)},
        {:name => '% Twitter', :op => :div, :series => %w(totalTwitter total)},
        {:name => '% Facebook', :op => :div, :series => %w(totalFacebook total)},
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
            :defaultSeriesType => 'area'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => "% of Photos and Albums Shared (Email/FB/Twitter)"
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
              :text => '% of Total'
            },
            :min => 0,
            :max => 1.0,
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

  def toolbar_frame_shares
    entity = case params[:entity]
      when 'photos' then 'photo'
      when 'albums' then 'album'
    end

    data_src = RollupData::UniversalDatasource.new(
      :percent_view => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %W(#{entity}.share.toolbar.facebook #{entity}.share.toolbar.twitter #{entity}.share.toolbar.email #{entity}.share.frame.facebook #{entity}.share.frame.twitter #{entity}.share.frame.email),
      :series_calculations => [
        {:name => 'totalFrame', :op => :sum, :series => %W(#{entity}.share.frame.facebook #{entity}.share.frame.twitter #{entity}.share.frame.email)},
        {:name => 'totalToolbar', :op => :sum, :series => %W(#{entity}.share.toolbar.facebook #{entity}.share.toolbar.twitter #{entity}.share.toolbar.email)},
        {:name => '% Toolbar', :op => :div, :series => %w(totalToolbar total)},
        {:name => '% Frame', :op => :div, :series => %w(totalFrame total)}
      ]
    )
    total_calc = {:name => 'total', :op => :sum, :series => %w(totalFrame totalToolbar)}
    total_pos = 2
    groups = %w(Toolbar Frame)
    if entity=='album'
      data_src.queries_to_fetch += %w(album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter)
      total_calc[:series] << 'totalGrouptab'
      groups << 'Group Tab'
      total_pos = 3
      data_src.series_calculations.insert(2, {:name => 'totalGrouptab', :op => :sum, :series => %W(album.share.group_tab.email album.share.group_tab.facebook album.share.group_tab.twitter)})
      data_src.series_calculations.insert(3, {:name => '% Group Tab', :op => :div, :series => %w(totalGrouptab total)})
    end
    data_src.series_calculations.insert(total_pos, total_calc)
    data_src.calculate_chart

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
            :text => "% of #{entity.camelcase}s Shared by #{groups.to_sentence}"
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
              :text => '% by Method'
            },
            :min => 0,
            :max => 1.0,
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


end
