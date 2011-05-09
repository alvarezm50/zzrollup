class AlbumSweep < BaseSweep
  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    minimal(span)
    grouped_query(db, "Albums.type", span,
               "SELECT type,count(id) FROM albums GROUP BY type ORDER BY type")
    grouped_query(db, "Albums.privacy", span,
               "SELECT privacy,count(id) FROM albums GROUP BY privacy ORDER BY privacy")
    grouped_query(db, "Albums.GroupAlbum.privacy", span,
               "SELECT privacy,count(id) FROM albums where type = 'GroupAlbum' GROUP BY privacy ORDER BY privacy")
    grouped_query(db, "Albums.ProfileAlbum.privacy", span,
               "SELECT privacy,count(id) FROM albums where type = 'ProfileAlbum' GROUP BY privacy ORDER BY privacy")
  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    full_query(db, "Albums.all", span,
               "SELECT count(*) FROM albums")
  end

end