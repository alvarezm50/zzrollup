class EvtSweep < BaseSweep
  def self.db
    return ZZADB.connection
  end

  def self.full(span)
    minimal(span)
    full_query(db, "Agent.first.use.all", span,
               "SELECT count(*) FROM evts WHERE event = 'agent.first.use'")
    grouped_query(db, "Page.visit.user", span,
               "SELECT user_type,count(id) FROM evts WHERE event = 'page.visit' AND source = 1 GROUP BY user_type ORDER BY user_type")
  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    full_query(db, "Page.visit.user.all", span,
               "SELECT count(*) FROM evts WHERE event = 'page.visit' AND source = 1")
  end
end