class Chart::TrendsController < HighchartsController
  def daily_growth
    categories = (1..31).to_a.map(&:to_s)
    data_src = TrendsDatasource.new(:query_name_mask => 'Photos.all', :calculate_now => true)
    
    source_data = {}
    data_src.chart_series.each_index do |i|
      next if i==0
      source_data[data_src.chart_series[i]['report_date']] = data_src.chart_series[i]['value'] - data_src.chart_series[i-1]['value']
    end
    
    data = {}
    source_data.each do |date, val|
      serie_name = Date.parse(date).strftime('%B')
      category = Date.parse(date).strftime('%d')
      data[serie_name] ||= {:name => serie_name, :data => Array.new(categories.size)}
      data[serie_name][:data][category.to_i - 1] = val
    end
    

    respond_to do |wants|
      wants.xls do
        send_xls(data_src)
      end
      wants.json do
        render :json => {
          :series => data.values,
          :chart => {
            :renderTo => '',
            :defaultSeriesType => 'line'
          },
          :credits => {
            :enabled => false
          },
          :title => {
            :text => 'Daily Growth of Photos By Month'
          },
          :xAxis => {
            :categories => categories,
            :tickmarkPlacement => 'on',
            :title => {
              :enabled => false
            },
          },
          :yAxis => {
            :title => {
              :text => 'Average # of Photos'
            },
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
