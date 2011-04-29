class PhotoSweep < BaseSweep
  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    full_query(db, "Photos.all", span,
               "SELECT count(*) FROM photos")
    grouped_query(db, "Photos.source", span,
               "SELECT source,count(id) FROM photos GROUP BY source ORDER BY source")
  end
end