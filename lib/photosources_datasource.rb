class PhotosourcesDatasource < CohortsDatasource
  attr_accessor :whole_history, :series_sum_scheme, :queries_to_fetch

  HUMAN_QUERY_NAMES = {
    'fs.osx' => 'Agent Mac',
    'fs.win' => 'Agent PC',
    'iphoto.osx' => 'iPhoto Mac',
    'kodak' => 'Kodak Gallery',
    'picasa.osx' => 'Picasa Mac',
    'picasa.win' => 'Picasa PC',
    'picasaweb' => 'Picasa Web',
    'simple.osx' => 'Simple Uploader Mac',
    'simple.win' => 'Simple Uploader PC',

    'webui' => 'Simple Uploader',
  }


  def calculate_chart
    fetch_data!
    transform_data!
    make_chart_series!
    sum_series!(@series_sum_scheme) if @series_sum_scheme
    humanize_series_names!
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
      "DATE_FORMAT(reported_at, '#{@x_labels_format}') AS report_date",
      "query_name",
      "MAX(sum_value) AS value"
    ]
    conditions = [
      RollupResult.public_sanitize_sql(:span => @span),
      "query_name IN (#{@queries_to_fetch.map{|q| "'Photos.source.#{q}'" }.join(',')})",
      #"(#{@queries_to_fetch.map{|q| "query_name = 'Photos.source.#{q}'" }.join(') OR (')})",
      'sum_value > 0'
    ]
    unless whole_history
      conditions << RollupResult.public_sanitize_sql(:reported_at => @period)
    end

    group_by = [
      'report_date',
      'query_name'
    ]

    sql = <<-SQL
      SELECT #{fields_to_select.join(',')} FROM `rollup_results` 
      WHERE (#{conditions.join(') AND (')}) GROUP BY #{group_by.join(',')} ORDER BY `reported_at` ASC
    SQL
    @rollup_data_rows = RollupResult.connection.select_all(sql)
  end
  
  def transform_data!
    @formed_data = {}
    @rollup_data_rows.each do |row|
      query = row['query_name'].gsub(/^Photos.source./, '')
      @formed_data[query] ||= {}
      @formed_data[query][row['report_date']] = row['value']
    end
  end

  def make_chart_series!
    @category_formatter ||= Proc.new {|original_category| original_category }
    @categories ||= @rollup_data_rows.map{|row| row['report_date']}.uniq


    @chart_series = @formed_data.map do |query, values|
      data_row = Array.new(@categories.size)
      values.each do |row_cat, val| #This should keep the order
        dest_cat = @category_formatter.call(row_cat)
        if idx = @categories.index(dest_cat)
          data_row[idx] = val.to_i
        end
      end
      {
        :name => query,
        :data => data_row
      }
    end
  end

  def sum_series!(new_series)
    computed_series = new_series.map do |new_serie_name, series_to_sum_names|
      series_to_sum = @chart_series.select{|s| series_to_sum_names.include?(s[:name]) }
      data_row_size = series_to_sum.map{|s| s[:data].size }.max
      data_row = Array.new(data_row_size) do |i|
        series_to_sum.map{|s| s[:data][i] || 0 }.sum
      end
      {
        :name => new_serie_name,
        :data => data_row
      }
    end
    series_to_exclude = new_series.values.flatten
    @chart_series.reject! { |s| series_to_exclude.include?(s[:name]) }
    @chart_series += computed_series
  end

  def humanize_series_names!
    @chart_series.each { |serie| serie[:name] = human_query_name(serie[:name]) }
    #@chart_series = @chart_series.sort_by{|s| s[:name] }
  end

  def human_query_name(query_name)
    HUMAN_QUERY_NAMES[query_name] || query_name.gsub('.', ' ').humanize
  end

  
end