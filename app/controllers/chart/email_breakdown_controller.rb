class Chart::EmailBreakdownController < HighchartsController
  before_filter :discover_entities

  def raw_stats
    data_src =RollupData::UniversalDatasource.new(
      :cumulative => false,
      :whole_history => true,
      :humanize_unknown_series => false,
      :queries_to_fetch => send_click_open_bounce + @urls
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
      :humanize_unknown_series => false,
      :queries_to_fetch => %W(email.#{@email_type}.#{@grid_entity}.click) + send_click_open_bounce + @urls,
      :series_calculations => [
        {:name => 'Open', :op => :div, :series => %W(email.#{@email_type}.open email.#{@email_type}.send)},
        {:name => 'Click', :op => :div, :series => %W(email.#{@email_type}.click email.#{@email_type}.send)},
        {:name => 'Bounce', :op => :div, :series => %W(email.#{@email_type}.bounce email.#{@email_type}.send)}
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
      :humanize_unknown_series => false,
      :queries_to_fetch => %W(email.#{@email_type}.#{@grid_entity}.click email.#{@email_type}.click) + @urls,
      :series_calculations => []
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
            :defaultSeriesType => 'area'
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
  def discover_entities
    @email_type = params[:email_type]
    @grid_entity = case @email_type
      when 'albumshared', 'likealbum', 'contributorinvite', 'welcome' then 'album_grid_url'
      when 'photoliked', 'photoshared' then 'album_photo_url'
      when 'userliked' then 'like_user_url'
      when 'albumsharedlike', 'photosready' then 'album_activities_url'
      when 'photocomment' then 'album_photo_url_with_comments'
    end

    @urls = RollupResult.connection.select_values("SELECT DISTINCT query_name FROM rollup_results WHERE query_name LIKE 'email.#{@email_type}.%_url%.click' AND span = 1440")
  end

  def send_click_open_bounce
    %W(email.#{@email_type}.send email.#{@email_type}.click	email.#{@email_type}.open	email.#{@email_type}.bounce)
  end

  def add_optional_trends(datasource) 
    if self.action_name=='link_breakdown'
      @urls.each do |url|
        datasource.series_calculations << {
          :name => "Clicks on #{url.gsub(/(^email\.|\.click$)/, '')}",
          :op => :div,
          :series => [url, "email.#{@email_type}.click"]
        }
      end
    elsif self.action_name=='full_stats'
      @urls.each do |url|
        datasource.series_calculations << {
          :name => "Link (#{url.gsub(/(^email\.|\.click$)/, '')})",
          :op => :div,
          :series => [url, "email.#{@email_type}.send"]
        }
      end
    end
  end

end
