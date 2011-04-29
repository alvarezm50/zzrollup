class ApplicationController < ActionController::Base
  protect_from_forgery

  def authenticate
    allowed = {
      :actions => [
      ]
    }
    basic_auth_user = ZangZingConfig.config[:basic_auth_user]
    basic_auth_password = ZangZingConfig.config[:basic_auth_password]
    unless allowed[:actions].include?("#{params[:controller]}##{params[:action]}")
      authenticate_or_request_with_http_basic('ZZRollup') do |username, password|
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
