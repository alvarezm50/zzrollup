class ZZADB < ActiveRecord::Base
  establish_connection(ZZADatabaseConfig.config)
end