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
    group_albums = fetch_query('Albums.type.GroupAlbum', true)
    public_albums = fetch_query('Albums.GroupAlbum.privacy.public', true)
    hidden_albums = fetch_query('Albums.GroupAlbum.privacy.hidden', true)
    password_albums = fetch_query('Albums.GroupAlbum.privacy.password', true)

    categories = group_albums.keys.uniq

    series = [
      {
        :name => 'Public albums',
        :data => categories.map { |cat| public_albums[cat].to_f / group_albums[cat] }
      },
      {
        :name => 'Hidden albums',
        :data => categories.map { |cat| hidden_albums[cat].to_f / group_albums[cat] }
      },
      {
        :name => 'Password albums',
        :data => categories.map { |cat| password_albums[cat].to_f / group_albums[cat] }
      }
    ]

    render :json => {
      :series => series,
      :chart => {
        :renderTo => '',
        :defaultSeriesType => 'column'
      },
      :xAxis => {
        :categories => categories
      },
      :yAxis => {
        :labels => { :formatter => nil },
        :title => {
          :text => nil
        },
      },
      :credits => {
        :enabled => false
      },
      :title => {
        :text => 'Monthly Avg % Allocation of Privacy Settings'
      },
      :subtitle => {
        :text => "(excludes Profile Albums)"
      },
      :tooltip => { :formatter => nil }
    }
  end

protected
  def average(arr)
    arr.inject(0.0) { |sum, el| sum + el } / arr.size
  end

  def fetch_query(query_name, monthly = false)
    sql = <<-SQL
      SELECT DATE_FORMAT(reported_at, '#{monthly ? '%b %Y' : '%Y-%m-%d'}') AS report_date, MAX(sum_value) AS value
        FROM rollup_results WHERE query_name = '#{query_name}' AND span=#{RollupTasks::DAILY_REPORT_INTERVAL} GROUP BY report_date ORDER BY reported_at
    SQL
    dataset = RollupResult.connection.select_all(sql)
    dataset.inject(ActiveSupport::OrderedHash.new) do |hsh, row|
      hsh[row['report_date']] = row['value'].to_i
      hsh
    end
  end

end
