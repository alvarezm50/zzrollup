class Chart::MiscController < HighchartsController
  
  def totals
    data_src = RollupData::UniversalDatasource.new(
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :span => params[:span],
      :cumulative => params[:non_cumulative]!='true',
      :queries_to_fetch => %w(photos.download.original),
      :calculate_now => true
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
            :text => "Number of Original Photos downloaded"
          },
          :subtitle => {
            :text => data_src.chart_subtitle
          },
          :legend => {
            :enabled => false
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
              :x => 4
            }
          },
          :yAxis => {
            :title => {
              :text => nil
            },
            :min => 0,
            :step => (data_src.categories.size/30.0).ceil
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

  def part_of_total
    data_src = RollupData::UniversalDatasource.new(
      :calculate_now => true,
      :period => (DateTime.civil(2011, 07, 13)..DateTime.now),
      :span => params[:span],
      :cumulative => params[:non_cumulative]!='true',
      :queries_to_fetch => %w(photos.download.original photos.all),
      :series_calculations => [
        {:name => 'Part of photos', :op => :div, :series => %W(photos.download.original photos.all)},
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
            :text => '% of Total Photos Downloaded'
          },
          :subtitle => {
            :text => data_src.chart_subtitle
          },
          :legend => {
            :enabled => false
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

end
