class Chart::PhotoSourcesController < HighchartsController

  def overall_categories
    data_src = PhotosourcesDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win),
      :series_sum_scheme => {
        'websites' => %w(facebook flickr instagram kodak photobucket picasaweb shutterfly	smugmug	zangzing),
        'agent' => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win),
        'webui' => %w(simple.osx simple.win)
      }
    )

    total = data_src.chart_series.inject(0.0) do |sum, s|
      sum + s[:data].compact.max
    end
    series = [{
        :type => 'pie',
        :data => data_src.chart_series.map do |serie|
          [serie[:name], serie[:data].compact.max / total]
        end
      }]

    respond_to do |wants|
      wants.xls do
        send_xls(series)
      end
      wants.json do
        render :json => {
          :series => series,
          :chart => {
            :renderTo => ''
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Photo Source: Overall Categories'
          },
          :plotOptions => {
             :pie => {
                :dataLabels => {
                    :formatter => nil,
                },
                :showInLegend => true
             }
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def specific_categories
    data_src = PhotosourcesDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win)
    )

    total = data_src.chart_series.inject(0.0) do |sum, s|
      sum + s[:data].compact.max
    end
    series = [{
        :type => 'pie',
        :data => data_src.chart_series.map do |serie|
          [serie[:name], serie[:data].compact.max / total]
        end
      }]

    respond_to do |wants|
      wants.xls do
        send_xls(series)
      end
      wants.json do
        render :json => {
          :series => series,
          :chart => {
            :renderTo => ''
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Photo Source: Specific Categories'
          },
          :plotOptions => {
             :pie => {
                :dataLabels => {
                    :formatter => nil,
                },
                :showInLegend => true
             }
          },
          :tooltip => { :formatter => nil }
        }
      end
    end
  end

  def uploader_agent_trend
    data_src = PhotosourcesDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :queries_to_fetch => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win),
      :series_sum_scheme => {
        'agent' => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win),
        'webui' => %w(simple.osx simple.win)
      }
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
            :text => 'Trend: Simple Uploader vs Agent'
          },
          :subtitle => {
            :text => '# of Photos'
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
              :text => 'Number of Photos'
            },
            :min => 0,
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
  
  def uploader_agent_percent
    data_src = PhotosourcesDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :percent_view => true,
      :queries_to_fetch => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win),
      :series_sum_scheme => {
        'agent' => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win),
        'webui' => %w(simple.osx simple.win)
      }
    )
    
    total = data_src.chart_series.inject(0.0) do |sum, s|
      sum + s[:data].compact.max
    end
    
    series = data_src.chart_series.dup
    series.each do |s|
      s[:data] = s[:data].map{|v| v / total }
    end


    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
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
            :text => 'Trend: Simple Uploader vs Agent'
          },
          :subtitle => {
            :text => 'Percentage'
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
              :text => '% of Photos'
            },
            :labels => {:formatter => nil},
            :min => 0.0
            #:max => 1.0
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

  def breakdown
    data_src = PhotosourcesDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win)
    )

    total = data_src.chart_series.inject(0.0) do |sum, s|
      sum + s[:data].compact.max
    end
    series = data_src.chart_series.dup
    series.each do |s|
      s[:data] = s[:data].map{|v| (v || 0.0) / total }
    end


    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
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
            :text => 'Photo Source Breakdown Over Time'
          },
          :subtitle => {
            :text => 'Percentage'
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
              :text => '% of Photos'
            },
            :labels => {:formatter => nil},
            :min => 0.0
            #:max => 1.0
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



end
