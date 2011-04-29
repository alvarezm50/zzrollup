Rollup::Application.routes.draw do
  get    '/daily_report'                  => 'results#daily_report_file',      :as => :daily_report_file
  get    '/daily_report_table'            => 'results#daily_report_table',      :as => :daily_report_table
end
