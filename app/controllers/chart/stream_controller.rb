class Chart::StreamController < ApplicationController
  def totals #num_albums
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => params[:non_cumulative]!='true',
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(album.stream.email album.stream.facebook album.stream.twitter)
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
            :text => "# of Albums Streamed (Email/FB/Twitter)"
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
              :text => '# of Albums'
            },
            :min => 0,
            :labels => {:formatter => nil}
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def percent_totals
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :span => params[:span] || 1440,
      :cumulative => params[:non_cumulative]!='true',
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(album.stream.email album.stream.facebook album.stream.twitter albums.all),
      :series_calculations => [
        {:name => 'Email', :op => :div, :series => %w(album.stream.email albums.all)},
        {:name => 'Facebook', :op => :div, :series => %w(album.stream.facebook albums.all)},
        {:name => 'Twitter', :op => :div, :series => %w(album.stream.twitter albums.all)}
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
            :text => '% of Albums Streamed (Email/FB/Twitter)'
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
              :text => '% of Total Albums'
            },
            :min => 0.0,
            :labels => {:formatter => nil}
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def percent_albums_by_type
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :queries_to_fetch => %w(album.stream.email album.stream.facebook album.stream.twitter),
      :series_calculations => [
        {:name => 'total', :op => :sum, :series => %w(album.stream.email album.stream.facebook album.stream.twitter)},
        {:name => 'email', :op => :div, :series => %w(album.stream.email total)},
        {:name => 'facebook', :op => :div, :series => %w(album.stream.facebook total)},
        {:name => 'twitter', :op => :div, :series => %w(album.stream.twitter total)}
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
            :text => '% of Email, FB and Twitter Streams'
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
              :text => '% of Total Streams'
            },
            :min => 0.0,
            :max => 1.0,
            :labels => {:formatter => nil}
          },
          :plotOptions => {
            :area => {
              :stacking => 'normal'
            }
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

end
