# Google analytics user tracking info
class GAUsers
  extend Garb::Model

  metrics :visits, :bounces, :time_on_site
  dimensions :visitor_type
end