class PhotoSweep < BaseSweep
  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    minimal(span)
    grouped_query(db, "Photos.source", span,
               "SELECT source,count(id) FROM photos GROUP BY source ORDER BY source")
  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    full_query(db, "Photos.all", span,
               "SELECT count(*) FROM photos")
  end
end