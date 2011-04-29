class EvtSweep < BaseSweep
  def self.db
    return ZZADB.connection
  end

  def self.full(span)
    full_query(db, "Page.visit.user.all", span,
               "SELECT count(*) FROM evts WHERE event = 'page.visit' AND source = 1")
    grouped_query(db, "Page.visit.user", span,
               "SELECT user_type,count(id) FROM evts WHERE event = 'page.visit' AND source = 1 GROUP BY user_type ORDER BY user_type")
  end
end