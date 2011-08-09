class UniversalDatasource < CohortsDatasource
  attr_accessor :whole_history, :queries_to_fetch, :series_calculations

  HUMAN_QUERY_NAMES = {
    #Photo sources (Photos.source)
    'photos.source.flickr' => 'Flickr',
    'photos.source.facebook' => 'Facebook',
    'photos.source.shutterfly' => 'Shutterfly',
    'photos.source.photobucket' => 'Photobucket',
    'photos.source.instagram' => 'Instagram',
    'photos.source.smugmug' => 'Smugmug',
    'photos.source.kodak' => 'Kodak Gallery',
    'photos.source.picasaweb' => 'Picasa Web',
    'photos.source.email' => 'E-Mail',
    'photos.source.zangzing' => 'ZangZing',
    'photos.source.fs.osx' => 'Agent Mac',
    'photos.source.fs.win' => 'Agent PC',
    'photos.source.iphoto.osx' => 'iPhoto Mac',
    'photos.source.picasa.osx' => 'Picasa Mac',
    'photos.source.picasa.win' => 'Picasa PC',
    'photos.source.simple.osx' => 'Simple Uploader Mac',
    'photos.source.simple.win' => 'Simple Uploader PC',

    'photos.source.simple' => 'Simple Uploader',
  }

  CALC_OPS = {
    :sum => Proc.new{|collector, element| (collector||0) + (element||0) },
    :div => Proc.new do |collector, element|
      res = collector.nil? ? element.to_f : (collector / element ) rescue nil
      (res.nil? || res.nan? || res.infinite?) ? nil : res
    end
  }


  def calculate_chart
    fetch_data!
    transform_data!
    make_chart_series!
    make_calculations! if @series_calculations
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
      "query_name IN (#{@queries_to_fetch.map{|q| "'#{q}'" }.join(',')})",
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
      query = row['query_name']
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

  def make_calculations!
    obsolete_series_names = []
    @series_calculations.each do |calc|
      series_to_operate = calc[:series].map do |target_serie_name|
        @chart_series.select{|s| target_serie_name.casecmp(s[:name])==0 }.first
      end
      obsolete_series_names += calc[:series].map(&:downcase)
      data_row_size = series_to_operate.map{|s| s[:data].size }.max
      data_row = Array.new(data_row_size) do |i|
        series_to_operate.inject(nil) do |accumulator, serie|
          CALC_OPS[calc[:op]].call(accumulator, serie[:data][i])
        end
      end
      @chart_series << {
        :name => calc[:name],
        :data => data_row
      }
    end
    @chart_series.reject! { |s| obsolete_series_names.include?(s[:name].downcase) }
  end

  def humanize_series_names!
    @chart_series.each { |serie| serie[:name] = human_query_name(serie[:name]) }
    #@chart_series = @chart_series.sort_by{|s| s[:name] }
  end

  def human_query_name(query_name)
    HUMAN_QUERY_NAMES[query_name.downcase] || query_name #.gsub('.', ' ').humanize
  end

  
end