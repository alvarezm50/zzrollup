class Chart::EmailBreakdownController < HighchartsController
  before_filter :detect_entity

  def raw_stats
    data_src = UniversalDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :humanize_unknown_series => false,
      :queries_to_fetch => %W(email.#{@entity}.send	email.#{@entity}.click	email.#{@entity}.open	email.#{@entity}.bounce)
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
            :text => 'Raw Statistics'
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
      :queries_to_fetch => %W(email.#{@entity}.#{@grid_entity}.click	email.#{@entity}.send	email.#{@entity}.click	email.#{@entity}.open	email.#{@entity}.bounce),
      :series_calculations => [
        {:name => 'Open', :op => :div, :series => %W(email.#{@entity}.open email.#{@entity}.send)},
        {:name => 'Click', :op => :div, :series => %W(email.#{@entity}.click email.#{@entity}.send)},
        {:name => 'Link', :op => :div, :series => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.send)},
        {:name => 'Bounce', :op => :div, :series => %W(email.#{@entity}.bounce email.#{@entity}.send)},
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
            :text => 'Statistics'
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
      :queries_to_fetch => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.click),
      :series_calculations => [
        {:name => '% Clicked', :op => :div, :series => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.click)},
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

protected
  def detect_entity
    @entity = case params[:entity]
      when 'album_share' then 'albumshared'
      when 'album_like' then 'likealbum'
      when 'photo_like' then 'photoliked'
      when 'user_like' then 'userliked'
      when 'album_updated' then 'albumsharedlike'
      when 'contributor_invite' then 'contributorinvite'
      when 'photo_shared' then 'photoshared'
      when 'photos_ready' then 'photosready'
      when 'welcome_email' then 'welcome'
    end
    @grid_entity = case @entity
      when 'albumshared', 'likealbum', 'contributorinvite', 'welcome' then 'album_grid_url'
      when 'photoliked', 'photoshared' then 'album_photo_url'
      when 'userliked' then 'like_user_url'
      when 'albumsharedlike', 'photosready' then 'album_activities_url'
    end
  end

end
