class EvtSweep < BaseSweep
  def self.db
    return ZZADB.connection
  end

  def self.full(span)
    full_query(db, "Agent.first.use.all", span,
               "SELECT count(*) FROM evts WHERE event = 'agent.first.use'")
    full_query(db, "Page.visit.user.all", span,
               "SELECT count(*) FROM evts WHERE event = 'page.visit' AND source = 1")
    grouped_query(db, "Page.visit.user", span,
               "SELECT user_type,count(id) FROM evts WHERE event = 'page.visit' AND source = 1 GROUP BY user_type ORDER BY user_type")
#    grouped_query(db, "", span, "
#      SELECT event, count(event) FROM evts WHERE
#      event LIKE 'user.join' OR
#      event LIKE 'button.createalbum.click%' OR
#      event LIKE 'album.add_photos_tab.view' OR
#      event LIKE 'album.name_tab.view' OR
#      event LIKE 'album.edit_tab.view' OR
#      event LIKE 'album.privacy_tab.view' OR
#      event LIKE 'album.contributors_tab.view' OR
#      event LIKE 'album.share_tab.view' OR
#      event LIKE 'album.done.click' OR
#      event LIKE 'email.welcome%' OR
#      event LIKE 'email.albumshared%' OR
#      event LIKE 'email.contributorinvite%'
#      GROUP BY event
#      ")
    # grab just about everything
    grouped_query(db, "", span, "
      SELECT event, count(event) FROM evts where
      event not like 'agent.%.run' and event not like '.%' and event not like ''
      group by event
      ")
  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    full_query(db, "Page.visit.user.all", span,
               "SELECT count(*) FROM evts WHERE event = 'page.visit' AND source = 1")
    full_query(db, "homepage.visit", span,
               "SELECT count(*) FROM evts WHERE event = 'homepage.visit'")
  end
end