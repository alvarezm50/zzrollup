Rollup::Application.routes.draw do
  get    '/daily_report'                  => 'results#daily_report_file',       :as => :daily_report_file
  get    '/daily_report_table'            => 'results#daily_report_table',      :as => :daily_report_table

  # geckoboard
  get    '/gecko_before_after'            => 'gecko#before_after',              :as => :gecko_before_after

  #charts
  match    '/:controller/:action', :controller => /chart\/[^\/]+/
  get '/dashboard_:action' => 'highcharts', :as => :dashboard

  root   :to => 'highcharts#cohorts'
end
