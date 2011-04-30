class ApplicationController < ActionController::Base
  before_filter :protect_with_http_auth
  protect_from_forgery

  def protect_with_http_auth
    allowed = Set.new (
#          'gecko#before_after'
    )
    basic_auth_user = ZangZingConfig.config[:basic_auth_user]
    basic_auth_password = ZangZingConfig.config[:basic_auth_password]
    method = "#{params[:controller]}##{params[:action]}"
    unless allowed.include?(method)
      authenticate_or_request_with_http_basic('ZZRollup') do |username, password|
        Rails.logger.info("UN: #{username}, PW: #{password}")
        return true if method == 'gecko#before_after'
        username == basic_auth_user && password == basic_auth_password
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
