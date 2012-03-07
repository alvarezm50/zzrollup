class Chart::ViralityController < HighchartsController

  def k_factor
    data_src = RollupData::UniversalDatasource.new(
      :period => (2.months.ago..DateTime.now),
      :span => params[:span],
      :queries_to_fetch => ["k_factor.#{params[:kind]}_user.#{params[:days]}_days"],
      :calculate_now => true
    )

    #Divide each value by 100
    data_src.chart_series.first[:data].map!{|val| val / 100.0 }

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
            :text => "K-Factor for #{params[:kind]} users (#{params[:days]} days) "
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


end
