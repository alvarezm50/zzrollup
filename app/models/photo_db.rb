class PhotoDB < ActiveRecord::Base
  establish_connection(PhotosDatabaseConfig.config)
end