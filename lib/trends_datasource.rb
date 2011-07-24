class TrendsDatasource < CohortsDatasource

  def calculate_chart
    fetch_data!
    @category_formatter ||= Proc.new {|original_category| original_category }
    @categories ||= @rollup_data_rows.map{|row| row['report_date']}.uniq
    make_chart_series!
  end

  
protected
  def default_period
    (8.weeks.ago..Time.now)
  end

  def fetch_data!
    @period ||= default_period
    @x_labels_format = '%Y-%m-%d'
    @span = RollupTasks::DAILY_REPORT_INTERVAL
    

    fields_to_select = []
    conditions = []
    group_by = []

    fields_to_select << "DATE_FORMAT(reported_at, '#{@x_labels_format}') AS report_date"
    fields_to_select << "MAX(sum_value) AS value"
    group_by << 'report_date'
    
    conditions << RollupResult.public_sanitize_sql(:reported_at => @period)
    conditions << RollupResult.public_sanitize_sql(["span = ? AND query_name = ?", @span, @query_name_mask])
    
    sql = <<-SQL
      SELECT #{fields_to_select.join(',')} FROM `rollup_results` 
      WHERE (#{conditions.join(') AND (')}) GROUP BY #{group_by.join(',')} ORDER BY `report_date`
    SQL
    @rollup_data_rows = RollupResult.connection.select_all(sql)
  end

  def make_chart_series!
    @chart_series = [
      {
        :name => 'Values',
        :data => @rollup_data_rows.inject(Array.new(@categories.size)) do |result_data, row|
          dest_cat = @category_formatter.call(row['report_date'])
          if idx = @categories.index(dest_cat)
            result_data[idx] = row['value']
          end
          result_data
        end
      }
    ]
  end

  
end