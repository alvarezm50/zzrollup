class ApplicationController < ActionController::Base
  before_filter :protect_with_http_auth
  protect_from_forgery

  def protect_with_http_auth
    @@allowed ||= Set.new [

    ]
    # special case for gecko and it's wacky scheme
    # authenticated with special user/pw
    @@gecko_custom ||= Set.new [
        'gecko#before_after',
        'highcharts#active_users_by_cohort'
    ]
    basic_auth_user = ZangZingConfig.config[:basic_auth_user]
    basic_auth_password = ZangZingConfig.config[:basic_auth_password]
    method = "#{params[:controller]}##{params[:action]}"
    unless @@allowed.include?(method)
      authenticate_or_request_with_http_basic('ZZRollup') do |username, password|
        ok = false
        if @@gecko_custom.include?(method)
          # special case the gecko board requests because they always pass X as password
          gecko_user = ZangZingConfig.config[:gecko_user]
          gecko_password = ZangZingConfig.config[:gecko_password]
          ok = username == gecko_user && password == gecko_password
        end
        # if didn't do gecko custom, check normal
        if ok == false
          ok = username == basic_auth_user && password == basic_auth_password
        end
        ok
      end
    end
  end

  def remote_client_ip
    request.env['REMOTE_ADDR']
  end

  def referrer_host
    begin
      request.referer.split('/')[2]
    rescue
      'N/A'
    end
  end
end
