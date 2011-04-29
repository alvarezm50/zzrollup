class AlbumSweep < BaseSweep
  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    full_query(db, "Albums.all", span,
               "SELECT count(*) FROM albums")
    grouped_query(db, "Albums.type", span,
               "SELECT type,count(id) FROM albums GROUP BY type ORDER BY type")
    grouped_query(db, "Albums.privacy", span,
               "SELECT privacy,count(id) FROM albums GROUP BY privacy ORDER BY privacy")
  end

end