Rollup::Application.routes.draw do
  get    '/daily_report'                  => 'results#daily_report_file',       :as => :daily_report_file
  get    '/daily_report_table'            => 'results#daily_report_table',      :as => :daily_report_table

  # geckoboard
  get    '/gecko_before_after'            => 'gecko#before_after',              :as => :gecko_before_after

  #charts
  match    '/:controller/:action', :controller => /chart\/[^\/]+/

  get 'dash_:action' => 'highcharts'

  root   :to => 'highcharts#dashboard'
end
