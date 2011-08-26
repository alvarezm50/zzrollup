class Chart::PhotoSourcesController < HighchartsController

  def overall_categories
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win).map{|q| "Photos.source.#{q}"},
      :series_calculations => [
        {:name => 'websites', :op => :sum, :series => %w(facebook flickr instagram kodak photobucket picasaweb shutterfly	smugmug	zangzing).map{|q| "Photos.source.#{q}"}},
        {:name => 'agent', :op => :sum, :series => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win).map{|q| "Photos.source.#{q}"}},
        {:name => 'photos.source.simple', :op => :sum, :series => %w(simple.osx simple.win).map{|q| "Photos.source.#{q}"}}
      ]
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
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win).map{|q| "Photos.source.#{q}"}
    )

    total = data_src.chart_series.inject(0.0) do |sum, s|
      sum + s[:data].compact.max
    end
    series = [{
        :type => 'pie',
        :data => data_src.chart_series.map do |serie|
          [serie[:name], serie[:data].compact.max / total]
        end.sort_by{|d| 1/d[1] }
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
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :queries_to_fetch => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win).map{|q| "Photos.source.#{q}"},
      :series_calculations => [
        {:name => 'agent', :op => :sum, :series => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win).map{|q| "Photos.source.#{q}"}},
        {:name => 'photos.source.simple', :op => :sum, :series => %w(simple.osx simple.win).map{|q| "Photos.source.#{q}"}}
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
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :whole_history => true,
      :percent_view => true,
      :queries_to_fetch => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win).map{|q| "Photos.source.#{q}"},
      :series_calculations => [
        {:name => 'agent', :op => :sum, :series => %w(fs.osx iphoto.osx picasa.osx fs.win picasa.win).map{|q| "Photos.source.#{q}"}},
        {:name => 'photos.source.simple', :op => :sum, :series => %w(simple.osx simple.win).map{|q| "Photos.source.#{q}"}}
      ]

    )
    
    data_row_size = data_src.chart_series.map{|s| s[:data].size }.max
    series = data_src.chart_series.dup
    totals = Array.new(data_row_size) do |i|
      series.inject(0.0) do |accumulator, serie|
        accumulator + (serie[:data][i] || 0)
      end
    end

    series.each do |s|
      s[:data].each_with_index do |v, i|
        s[:data][i] = (v || 0.0) / totals[i]
      end
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
            :defaultSeriesType => 'area'
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
            :min => 0.0,
            :max => 1.0
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
    data_src =RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :percent_view => true,
      :whole_history => true,
      :queries_to_fetch => %w(email facebook flickr instagram kodak photobucket picasaweb shutterfly smugmug zangzing fs.osx iphoto.osx picasa.osx fs.win picasa.win simple.osx simple.win).map{|q| "Photos.source.#{q}"}
    )

    data_row_size = data_src.chart_series.map{|s| s[:data].size }.max
    series = data_src.chart_series.dup
    totals = Array.new(data_row_size) do |i|
      series.inject(0.0) do |accumulator, serie|
        accumulator + (serie[:data][i] || 0)
      end
    end

    series.each do |s|
      s[:data].each_with_index do |v, i|
        s[:data][i] = (v || 0.0) / totals[i]
      end
    end
    series = series.sort_by{|s| 1.0 / (s[:data].compact.sum / s[:data].compact.size) }


    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
        render :json => {
          :series => series,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'area'
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
            :min => 0.0,
            :max => 1.0
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
