# perform the periodic sweeps related to users
class UserSweep < BaseSweep

  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    minimal(span)
    full_query(db, "Users.active", span,
               "SELECT count(*) FROM users WHERE active=1")
    full_query(db, "Users.inactive", span,
               "SELECT count(*) FROM users WHERE active=0")
  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    full_query(db, "Users.all", span,
               "SELECT count(*) FROM users")
  end

end

