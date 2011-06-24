class Chart::PrivacySettingsController < HighchartsController
  def group_albums_privacy_allocation
    group_albums = fetch_query('Albums.type.GroupAlbum')
    public_albums = fetch_query('Albums.GroupAlbum.privacy.public')
    hidden_albums = fetch_query('Albums.GroupAlbum.privacy.hidden')
    password_albums = fetch_query('Albums.GroupAlbum.privacy.password')

    render :json => {
      :series => [{
        :type => 'pie',
        :data => [
          ['Public albums', public_albums.values.first.to_f / group_albums.values.first ],
          ['Hidden albums', hidden_albums.values.first.to_f / group_albums.values.first],
          ['Password albums', password_albums.values.first.to_f / group_albums.values.first],
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

    render :json => {
      :series => [{
        :type => 'pie',
        :data => [
          ['Group albums', group_albums.values.first.to_f / all_albums.values.first],
          ['Profile albums', profile_albums.values.first.to_f / all_albums.values.first]
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

    group_albums.reject!{ |k,v| !(public_albums.has_key?(k) && hidden_albums.has_key?(k) && password_albums.has_key?(k)) }

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
  def fetch_query(query_name, monthly = false)
    if monthly
      sql = <<-SQL
       SELECT DATE_FORMAT(reported_at, '%b %Y') AS report_date, MAX(sum_value) AS sum_value
          FROM rollup_results WHERE query_name = '#{query_name}' AND span=#{RollupTasks::DAILY_REPORT_INTERVAL} GROUP BY report_date ORDER BY reported_at
      SQL
    else  
      sql = <<-SQL
        SELECT DATE_FORMAT(reported_at, '%Y-%m-%d') AS report_date, sum_value
          FROM rollup_results WHERE query_name = '#{query_name}' AND span=#{RollupTasks::DAILY_REPORT_INTERVAL} ORDER BY reported_at DESC LIMIT 1
      SQL
    end
    dataset = RollupResult.connection.select_all(sql)
    dataset.inject(ActiveSupport::OrderedHash.new) do |hsh, row|
      hsh[row['report_date']] = row['sum_value'].to_i
      hsh
    end
  end

end
