# perform the periodic sweeps related to cohorts
class CohortSweep < BaseSweep

  # produce the results for the date range given
  # this is a multi step process because it requires
  # users to share something and from the set of users
  # that have shared something they must also have created
  # at least 10 photos
  # from the results, we determine the summary counts
  # by cohort
  def self.active_users(span, first, last)
    mgr = CohortManager.new("Cohort.users.active", span, first, last)

    # first find the users that have shares within the range
    mgr.add_users_query(ZZADB.connection,
               lambda {|begin_date, end_date| "
SELECT DISTINCT user FROM evts
WHERE (event LIKE 'photo.share.%' OR event LIKE 'album.share.%' OR event LIKE 'album.stream.%' OR event LIKE 'user.share.%') AND (stimestamp  >= #{begin_date} AND stimestamp < #{end_date}) AND user_type = 1
               "})

#    # now collect the cohorts within the range
#    # this form produces results by summing and matching directly
#    # against the user ids, the alternative form below uses an IN clause to
#    # produce results in the database
#    sums = mgr.cohorts_query_local_merge(PhotoDB.connection,
#               lambda {|begin_date, end_date| "
#SELECT u.id, cohort, count(p.id) as photo_count FROM users as u, photos as p
#WHERE u.id = p.user_id AND
#(p.created_at  >= #{begin_date} AND p.created_at < #{end_date})
#GROUP BY u.id
#HAVING photo_count >= 10
#    "})

    # collect the cohorts that match this condition and
    # are limited by the set of users we've collected with
    # shares
    sums = mgr.cohorts_query_in(PhotoDB.connection,
               lambda {|begin_date, end_date, in_set|  "
SELECT ru.cohort, count(ru.cohort) FROM
  (SELECT u.id, cohort, count(p.id) as photo_count FROM users as u, photos as p
  WHERE u.id = p.user_id AND auto_by_contact=false AND
  (p.created_at  >= #{begin_date} AND p.created_at < #{end_date})
  GROUP BY u.id
  HAVING photo_count >= 10) as ru
WHERE ru.id IN #{in_set}
GROUP BY ru.cohort
    "})

    # change the query name but keep the ids of the shares we've already fetched
    # now collect the cohorts within the range using the user ids already added
    # from an IN clause that is built
    # we are not called if there are no user_ids, also, we can be called
    # multiple times if their are a very large number of ids
    mgr.name = "Cohort.shares"
    sums = mgr.cohorts_query_in(PhotoDB.connection,
               lambda {|begin_date, end_date, in_set|  "
SELECT cohort, count(id) FROM users
WHERE id IN #{in_set} AND auto_by_contact=false
GROUP BY cohort
    "})

    # collect the photos by cohort but not limited by the shares
    # in otherwords, all photos created over the time range grouped
    # into their cohorts
    mgr.name = "Cohort.photos_10"
    sums = mgr.cohorts_query(PhotoDB.connection,
               lambda {|begin_date, end_date|  "
SELECT ru.cohort, count(ru.cohort) FROM
  (SELECT u.id, cohort, count(p.id) as photo_count FROM users as u, photos as p
  WHERE u.id = p.user_id AND auto_by_contact=false AND
  (p.created_at  >= #{begin_date} AND p.created_at < #{end_date})
  GROUP BY u.id
  HAVING photo_count >= 10) as ru
GROUP BY ru.cohort
    "})

    mgr.name = "Cohort.photos_1"
    sums = mgr.cohorts_query(PhotoDB.connection,
               lambda {|begin_date, end_date|  "
SELECT ru.cohort, count(ru.cohort) FROM
  (SELECT u.id, cohort, count(p.id) as photo_count FROM users as u, photos as p
  WHERE u.id = p.user_id AND auto_by_contact=false AND
  (p.created_at  >= #{begin_date} AND p.created_at < #{end_date})
  GROUP BY u.id
  HAVING photo_count >= 1) as ru
GROUP BY ru.cohort
    "})


#    mgr = CohortManager.new("dummy", span, first, last)
#    # first find the users that have likes within the range
#    mgr.add_users_query(ZZADB.connection,
#               lambda {|begin_date, end_date| "
#SELECT DISTINCT user FROM evts
#WHERE (event LIKE 'like.user.%' OR event LIKE 'like.album.%' OR event LIKE 'like.photo.%') AND (stimestamp  >= #{begin_date} AND stimestamp < #{end_date}) AND user_type = 1
#               "})
#
#    # 8+ follows
#    mgr.name = "Cohort.follow_8"
#    sums = mgr.cohorts_query_in(PhotoDB.connection,
#               lambda {|begin_date, end_date, in_set| "
#SELECT ru.cohort, count(ru.cohort) FROM
#  (SELECT u.id, cohort, count(l.id) as likes_count FROM users as u, likes as l
#  WHERE u.id = l.subject_id AND l.subject_type = 'U' AND
#  u.id IN #{in_set}
#  GROUP BY u.id
#  HAVING likes_count >= 8) as ru
#GROUP BY ru.cohort
#    "})
#
#    # 5+ photo likes
#    mgr.name = "Cohort.photo_like_5"
#    sums = mgr.cohorts_query_in(PhotoDB.connection,
#               lambda {|begin_date, end_date, in_set| "
#SELECT ru.cohort, count(ru.cohort) FROM
#  (SELECT p.id, cohort, count(l.id) as likes_count FROM photos as p, likes as l, users AS u
#  WHERE p.id = l.subject_id AND l.subject_type = 'P' AND p.user_id = u.id AND
#  p.user_id IN #{in_set}
#  GROUP BY p.user_id
#  HAVING likes_count >= 5) as ru
#GROUP BY ru.cohort
#    "})
#
#    # 1 album like
#    mgr.name = "Cohort.album_like_1"
#    sums = mgr.cohorts_query_in(PhotoDB.connection,
#               lambda {|begin_date, end_date, in_set|  "
#SELECT ru.cohort, count(ru.cohort) FROM
#  (SELECT a.id, cohort, count(l.id) as likes_count FROM albums as a, likes as l, users AS u
#  WHERE a.id = l.subject_id AND l.subject_type = 'A' AND a.user_id = u.id AND
#  a.user_id IN #{in_set}
#  GROUP BY a.user_id
#  HAVING likes_count >= 1) as ru
#GROUP BY ru.cohort
#    "})

  end

  # Get the total users per cohort and a sum of all
  def self.total_users(span, first, last)
    grouped_query(PhotoDB.connection, "Cohort.users", span,
               "SELECT cohort, count(id) FROM users WHERE auto_by_contact=false GROUP BY cohort ORDER BY cohort", true, true)
  end


  def self.monthly(span)
    last = RollupTasks.now
    # back up to beginning of the month we are in
    first = DateTime.civil(last.year, last.month, 1, 0, 0, 0)
    active_users(span, first, last)
    total_users(span, first, last)
  end

  # this is the rollup for the previous 30 days
  def self.full(span)
    last = RollupTasks.now
    first = last - 30.days
    minimal(span)
    active_users(span, first, last)
    total_users(span, first, last)
  end

  def self.minimal(span)

  end
end

