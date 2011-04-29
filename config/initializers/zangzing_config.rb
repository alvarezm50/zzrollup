require "active_support/core_ext/hash"

class Hash
  def to_url_params
    self.map { |k,v| "#{k.to_s}=#{CGI.escape(v.to_s)}"}.join("&")
  end

  # A method to recursively symbolize all keys in the Hash class
  def recursively_symbolize_keys!
    self.symbolize_keys!
    self.values.each do |v|
      if v.is_a? Hash
        v.recursively_symbolize_keys!
      elsif v.is_a? Array
        #v.recursively_symbolize_keys!
      end
    end
    self
  end
end

# this class hold onto the zangzing_environment data from the same named yml
# use it for generic stuff that you'd like to control on a per environment basis
#

# determine the rails env in a manner that works
# with rspec tests and directly from rails
def safe_rails_env
  if defined?(Rails)
    return Rails.env
  else
    return ENV['RAILS_ENV']
  end
end

class ZangZingConfig
  def self.config
    @@config ||= YAML::load(ERB.new(File.read(File.dirname(__FILE__) + "/../zangzing_config.yml")).result)[safe_rails_env].recursively_symbolize_keys!
  end
end

# this class wraps database config - putting it here to avoid having too many
# init files
class DatabaseConfig
  def self.config
    @@config ||= YAML::load(ERB.new(File.read(File.dirname(__FILE__) + "/../database.yml")).result)[safe_rails_env].recursively_symbolize_keys!
  end
end

# this class wraps the zza database config - putting it here to avoid having too many
# init files
class ZZADatabaseConfig
  def self.config
    @@config ||= YAML::load(ERB.new(File.read(File.dirname(__FILE__) + "/../database-zza.yml")).result)[safe_rails_env].recursively_symbolize_keys!
  end
end

# this class wraps the zza database config - putting it here to avoid having too many
# init files
class PhotosDatabaseConfig
  def self.config
    @@config ||= YAML::load(ERB.new(File.read(File.dirname(__FILE__) + "/../database-photos.yml")).result)[safe_rails_env].recursively_symbolize_keys!
  end
end
