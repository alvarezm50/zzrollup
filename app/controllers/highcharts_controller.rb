class HighchartsController < ApplicationController

protected

  def send_xls(datasource, series = nil)
    send_data datasource.produce_xls(series), :content_type => Mime::XLS, :filename => "#{params[:action]}_#{datasource.span_code}_#{DateTime.now.strftime('%Y%m%d%H%M')}.xls"
  end


end
