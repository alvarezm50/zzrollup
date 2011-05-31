# google analytics sweeper
class GASweep < BaseSweep
  def self.establish_session
    @@session_valid ||= false
    return if @@session_valid

    # create the google analytics session
    username = ZangZingConfig.config[:ga_user]
    password = ZangZingConfig.config[:ga_password]
    Garb::Session.login(username, password)
    @@session_valid = true

    @@stats_start_data = Date.parse(ZangZingConfig.config[:ga_stats_start_date])
  end

  def self.get_profile(id)
    profiles = Garb::Management::Profile.all
    profiles.each do |profile|
      if profile.web_property_id == id
        return profile
      end
    end

    raise "Google Analytics: Profile Not Found for #{id}"
  end

  def self.test
    RollupTasks.set_now
    full(1440)
  end

  def self.full(span)
    establish_session
    minimal(span)

    profile = get_profile(ZangZingConfig.config[:ga_web_property_id])
    results = GAUsers.results(profile, {:start_date => @@stats_start_data, :end_date => RollupTasks.now})
    rcount = results.count
    raise "Google Analytics: Number of results expected was 2 but got #{rcount}." if rcount != 2
    rows = []
    results.each do |r|
      base_name = r.visitor_type == "New Visitor" ? "ga.user.new" : "ga.user.returning"

      row = ["#{base_name}", r.visits]
      rows << row

      row = ["#{base_name}.bounces", r.bounces]
      rows << row

      row = ["#{base_name}.time_on_site", r.time_on_site]
      rows << row
    end
    save_results(rows, span)

  end

  # this gets called at high frequency so only collect a few interesting stats
  def self.minimal(span)
    establish_session
  end
end