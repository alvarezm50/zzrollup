module RollupData
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

      fields_to_select = [
        "DATE_FORMAT(SUBDATE(`reported_at`, INTERVAL WEEKDAY(`reported_at`) DAY), '#{@x_labels_format}') AS report_date",
        "ROUND(AVG(sum_value)) AS value",
        "DATE_FORMAT(reported_at, '%v %x') AS weekyear"
      ]
      conditions = [
        RollupResult.public_sanitize_sql(:reported_at => @period),
        RollupResult.public_sanitize_sql(["span = ? AND query_name = ?", @span, @query_name_mask]),
        RollupResult.public_sanitize_sql('sum_value > 0')
      ]
      group_by = [
        'weekyear'
      ]

      sql = <<-SQL
        SELECT #{fields_to_select.join(',')} FROM `rollup_results`
        WHERE (#{conditions.join(') AND (')}) GROUP BY #{group_by.join(',')} ORDER BY `reported_at` ASC
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
              result_data[idx] = row['value'].to_i
            end
            result_data
          end
        }
      ]
    end


  end
end