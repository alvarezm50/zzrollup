class Chart::EmailBreakdownController < HighchartsController
  before_filter :detect_entity

  def raw_stats
    data_src =RollupData::UniversalDatasource.new(
      :cumulative => false,
      :whole_history => true,
      :humanize_unknown_series => false,
      :queries_to_fetch => %W(email.#{@entity}.send	email.#{@entity}.click	email.#{@entity}.open	email.#{@entity}.bounce email.#{@entity}.#{@grid_entity}.click)
    )
    add_optional_trends(data_src)
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
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Number of Occurrences'
          },
          :subtitle => {
            :text => "On a #{data_src.span_code} basis"
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
              :text => '# of Occurences'
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
    data_src =RollupData::UniversalDatasource.new(
      :whole_history => true,
      :cumulative => false,
      :queries_to_fetch => %W(email.#{@entity}.#{@grid_entity}.click	email.#{@entity}.send	email.#{@entity}.click	email.#{@entity}.open	email.#{@entity}.bounce),
      :series_calculations => [
        {:name => 'Open', :op => :div, :series => %W(email.#{@entity}.open email.#{@entity}.send)},
        {:name => 'Click', :op => :div, :series => %W(email.#{@entity}.click email.#{@entity}.send)},
        {:name => "Link (#{@entity}.#{@grid_entity})", :op => :div, :series => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.send)},
        {:name => 'Bounce', :op => :div, :series => %W(email.#{@entity}.bounce email.#{@entity}.send)},
      ]
    )
    add_optional_trends(data_src)
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
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Events Occurrences as a % of Sent Emails'
          },
          :subtitle => {
            :text => "On a #{data_src.span_code} basis"
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
    data_src =RollupData::UniversalDatasource.new(
      :whole_history => true,  #:period => (DateTime.civil(2011, 07, 20)..DateTime.now),
      :percent_view => true,
      :cumulative => false,
      :queries_to_fetch => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.click),
      :series_calculations => [
        {:name => "Clicks on #{@grid_entity}", :op => :div, :series => %W(email.#{@entity}.#{@grid_entity}.click email.#{@entity}.click)},
      ]
    )
    add_optional_trends(data_src)
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
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Link Breakdown'
          },
          :subtitle => {
            :text => "As a % of total clicks"
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
              :text => "% of Total Clicks"
            },
            :min => 0.0,
            :max => 1.0,
            :labels => {:formatter => nil}
          },
          :tooltip => {:formatter => nil},
          #:legend => {:enabled => false},
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
      #email.photocomment.album_photo_url_with_comments.click
      when 'photo_comment' then 'photocomment'
    end
    @grid_entity = case @entity
      when 'albumshared', 'likealbum', 'contributorinvite', 'welcome' then 'album_grid_url'
      when 'photoliked', 'photoshared' then 'album_photo_url'
      when 'userliked' then 'like_user_url'
      when 'albumsharedlike', 'photosready' then 'album_activities_url'
      when 'photocomment' then 'album_photo_url_with_comments'
    end
  end

  def add_optional_trends(datasource) 
    if %w(likealbum photoliked userliked welcome).include?(@entity)
      if self.action_name=='link_breakdown'
        datasource.queries_to_fetch << "email.#{@entity}.user_homepage_url.click"
        datasource.series_calculations << {
          :name => "Clicks on user_homepage_url",
          :op => :div,
          :series => %W(email.#{@entity}.user_homepage_url.click email.#{@entity}.click)
        }
      elsif self.action_name=='raw_stats'
        datasource.queries_to_fetch << "email.#{@entity}.user_homepage_url.click"
      elsif self.action_name=='full_stats'
        datasource.queries_to_fetch << "email.#{@entity}.user_homepage_url.click"
        datasource.series_calculations << {
          :name => "Link (#{@entity}.user_homepage_url)",
          :op => :div,
          :series => %W(email.#{@entity}.user_homepage_url.click email.#{@entity}.send)
        }
      end
    end
  end

end
