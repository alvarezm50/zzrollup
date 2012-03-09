class KFactorSweep < BaseSweep
  def self.db
    return PhotoDB.connection
  end

  def self.full(span)
    [:new, :visiting].each do |set_type|
      [1, 7, 30].each do |days_count|
        query_name = "k_factor.#{set_type}_user.#{days_count}_days"
        k_value = calc_k_value(days_count, set_type)
        roll_result = RollupResult.create_result(query_name, span)
        roll_result.sum_value = k_value
        roll_result.save()
      end
    end
  end

  def self.calc_k_value(days_count, set_type)
    time_field = if set_type == :new
      'created_at'
    elsif set_type == :visiting
      'last_request_at'
    else
      raise ArgumentError.new("Unsupported set type - #{set_type}")
    end

    # this is the number of invitations that were sent and completed
    # during time period by active or joined users
    completed_invitations_sent_query = <<-SQL
      select count(distinct invitations.id) from invitations, tracked_links, users
        where invitations.tracked_link_id = tracked_links.id
          and tracked_links.created_at > DATE_ADD(NOW(), INTERVAL -#{days_count} DAY)
          and invitations.status = 'complete'
          and tracked_links.user_id = users.id
          and users.#{time_field} > DATE_ADD(NOW(), INTERVAL -#{days_count} DAY)
    SQL

    # this is the total number of active or joined users during time perion
    users_count_query = "select count(*) from users where #{time_field} > DATE_ADD(NOW(), INTERVAL -#{days_count} DAY)"

    # we need to remove these because they joined from an invite during this period and so shouldn't count against us
    users_joined_from_invite_query = <<-SQL
        select count(distinct users.id) from invitations, tracked_links, users
           where invitations.tracked_link_id = tracked_links.id
             and tracked_links.created_at > DATE_ADD(NOW(), INTERVAL -#{days_count} DAY)
             and invitations.status = 'complete'
		         and invitations.invited_user_id = users.id
    SQL

    completed_invitations_sent = db.select_value(completed_invitations_sent_query)
    users_count = db.select_value(users_count_query)
    users_joined_from_invite_count = db.select_value(users_joined_from_invite_query)

    k = completed_invitations_sent.to_f / (users_count - users_joined_from_invite_count)
    k.nan? ? nil : k*100
  end

end