class RollupDB < ActiveRecord::Base
  establish_connection(DatabaseConfig.config)
end