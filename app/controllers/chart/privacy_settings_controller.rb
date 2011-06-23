class Chart::PrivacySettingsController < HighchartsController
  def group_albums_privacy_allocation
    group_albums = fetch_query('Albums.type.GroupAlbum')
    public_albums = fetch_query('Albums.GroupAlbum.privacy.public')
    hidden_albums = fetch_query('Albums.GroupAlbum.privacy.hidden')
    password_albums = fetch_query('Albums.GroupAlbum.privacy.password')

    public_perc = public_albums.map { |date, val| val.to_f / group_albums[date] }
    hidden_perc = hidden_albums.map { |date, val| val.to_f / group_albums[date] }
    password_perc = password_albums.map { |date, val| val.to_f / group_albums[date] }

    render :json => {
      :series => [{
        :type => 'pie',
        :data => [
          ['Public albums', average(public_perc)],
          ['Hidden albums', average(hidden_perc)],
          ['Password albums', average(password_perc)],
        ]
      }],
      :chart => {
        :renderTo => ''
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Average % Allocation of Privacy Settings'
      },
      :subtitle => {
        :text => "(excludes Profile Albums)"
      },
      :plotOptions => {
         :pie => {
            :dataLabels => {
                :connectorWidth => 0,
                :distance => -30,
                :formatter => nil,
            },
            :showInLegend => true
         }
      },
      :tooltip => { :formatter => nil }
    }
  end

  def all_albums_privacy_allocation
    all_albums = fetch_query('Albums.all')
    group_albums = fetch_query('Albums.type.GroupAlbum')
    profile_albums = fetch_query('Albums.type.ProfileAlbum')

    group_perc = group_albums.map { |date, val| val.to_f / all_albums[date] }
    profile_perc = profile_albums.map { |date, val| val.to_f / all_albums[date] }

    render :json => {
      :series => [{
        :type => 'pie',
        :data => [
          ['Group albums', average(group_perc)],
          ['Profile albums', average(profile_perc)]
        ]
      }],
      :chart => {
        :renderTo => ''
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Average % Allocation of Privacy Settings'
      },
      :plotOptions => {
         :pie => {
            :dataLabels => {
                :connectorWidth => 0,
                :distance => -30,
                :formatter => nil,
            },
            :showInLegend => true
         }
      },
      :tooltip => { :formatter => nil }
    }
  end


  def monthly_privacy_allocation
  end

protected
  def average(arr)
    arr.inject(0.0) { |sum, el| sum + el } / arr.size
  end

  def fetch_query(query_name)
    sql = <<-SQL
      SELECT DATE_FORMAT(reported_at, '%Y-%m-%d') AS report_date, MAX(sum_value) AS value
        FROM rollup_results WHERE query_name = '#{query_name}' GROUP BY report_date;
    SQL
    dataset = RollupResult.connection.select_all(sql)

    result = {}
    dataset.each do |row|
      result[row['report_date']] = row['value'].to_i
    end
    result
  end

end
