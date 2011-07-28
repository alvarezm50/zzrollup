class DailyGrowthDatasource < TrendsDatasource

protected
  def fetch_data!
    @period ||= default_period
    @x_labels_format = '%Y-%m-%d'
    @span = RollupTasks::DAILY_REPORT_INTERVAL
    

    fields_to_select = [
      "DATE_FORMAT(reported_at, '#{@x_labels_format}') AS report_date",
      "MAX(sum_value) AS value"
    ]
    conditions = [
      RollupResult.public_sanitize_sql(:reported_at => @period),
      RollupResult.public_sanitize_sql(["span = ? AND query_name = ?", @span, @query_name_mask])
    ]
    group_by = [
      'report_date'
      ]
    
    sql = <<-SQL
      SELECT #{fields_to_select.join(',')} FROM `rollup_results` 
      WHERE (#{conditions.join(') AND (')}) GROUP BY #{group_by.join(',')} ORDER BY `report_date`
    SQL
    @rollup_data_rows = RollupResult.connection.select_all(sql)
  end

  def make_chart_series!
    @categories = (1..31).to_a.map{|d| "Day #{d}" }

    source_data = {}
    @rollup_data_rows.each_index do |i|
      next if i==0
      source_data[@rollup_data_rows[i]['report_date']] = @rollup_data_rows[i]['value'] - @rollup_data_rows[i-1]['value']
    end

    data = {}
    source_data.each do |date, val|
      serie_name = Date.parse(date).strftime('%B')
      category = Date.parse(date).strftime('Day %d')
      data[serie_name] ||= {:name => serie_name, :data => Array.new(@categories.size)}
      data[serie_name][:data][category.scan(/\d+/).first.to_i - 1] = val
    end
    @chart_series = data.values
  end


end