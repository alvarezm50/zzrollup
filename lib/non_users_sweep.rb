class NonUsersSweep < BaseSweep
  def self.db
    ZZADB.connection
  end

  def self.full(span)
    unique_nonreg_emails(span)
  end

  def self.unique_nonreg_emails(span)
    [:mean, :median].each do |set_type|
      query_name = "share.email.unique_non_users.#{set_type}"

      uniq_nonreg = db.select_values("select xdata from evts where event = 'share.email.stats' and stimestamp > DATE_ADD(NOW(), INTERVAL -5 DAY)").map{|raw_json| JSON.parse(raw_json)['unique_non_reg_emails'] || 0 }

      stat_value = uniq_nonreg.send(set_type)
      roll_result = RollupResult.create_result(query_name, span)
      roll_result.sum_value = stat_value * 100
      roll_result.save
    end
  end


end