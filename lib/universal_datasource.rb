class UniversalDatasource < CohortsDatasource
  attr_accessor :whole_history, :queries_to_fetch, :series_calculations, :humanize_unknown_series, :cumulative, :colorize
  TYPE_COLORS = {
    :album => '#AA4643', #red/maroon
    :photo => '#4572A7', #blue
    :user => '#89A54E', #green
    :twitter => '#AA4643', #red/maroon
    :email => '#4572A7', #blue
    :facebook => '#89A54E' #green
  }

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
    #Likes
    'like.album.like' => 'Album like',
    'like.photo.like' => 'Photo like',
    'like.user.like' => 'User like',
    'like.album.unlike' => 'Album unlike',
    'like.photo.unlike' => 'Photo unlike',
    'like.user.unlike'=> 'User unlike',
    #Shares
    'photo.share.email' => 'via EMail',
    'photo.share.facebook' => 'via Facebook',
    'photo.share.twitter' => 'via Twitter',
    'album.share.email' => 'via EMail',
    'album.share.facebook' => 'via Facebook',
    'album.share.twitter' => 'via Twitter',
  }

  CALC_OPS = {
    :sum => Proc.new{|collector, element| (collector||0) + (element||0) },
    :div => Proc.new do |collector, element|
      res = collector.nil? ? element.to_f : (collector / element ) rescue nil
      (res.nil? || res.nan? || res.infinite?) ? nil : res
    end
  }

  def initialize(opts = {})
    @humanize_unknown_series = true
    @cumulative = true
    @colorize = false
    self.span = RollupTasks::DAILY_REPORT_INTERVAL
    super(opts)
  end

  def calculate_chart
    fetch_data!
    transform_data!
    make_chart_series!
    make_calculations! if @series_calculations
    humanize_series_names!
  end

  def chart_subtitle
    "#{@cumulative ? 'Cumulative' : 'Non-cumulative'}, on a #{@span_code} basis"
  end

  
protected
  def default_period
    (8.weeks.ago..Time.now)
  end

  def fetch_data!
    @period ||= default_period
    @x_labels_format = '%Y-%m-%d'
    @real_span = RollupTasks::DAILY_REPORT_INTERVAL

    fields_to_select = [
      "query_name",
    ]
    group_by = [
      'query_name'
    ]
    conditions = [
      RollupResult.public_sanitize_sql(:span => @real_span),
      "query_name IN (#{@queries_to_fetch.map{|q| "'#{q}'" }.join(',')})",
      'sum_value > 0'
    ]

    if @weekly_mode
      fields_to_select << "DATE_FORMAT(SUBDATE(`reported_at`, INTERVAL WEEKDAY(`reported_at`) DAY), '#{@x_labels_format}') AS report_date"
      if @cumulative
        fields_to_select << "ROUND(AVG(sum_value)) AS value"
      else
        fields_to_select << "GROUP_CONCAT(sum_value) AS value"
        fields_to_select << "GROUP_CONCAT(reported_at) AS value_order"
      end
      fields_to_select << "DATE_FORMAT(reported_at, '%v %x') AS weekyear"
      group_by << 'weekyear'
      conditions << RollupResult.public_sanitize_sql('sum_value > 0')
    else
      fields_to_select << "DATE_FORMAT(reported_at, '#{@x_labels_format}') AS report_date"
      fields_to_select << "MAX(sum_value) AS value"
      group_by << 'report_date'
    end

    unless whole_history
      conditions << RollupResult.public_sanitize_sql(:reported_at => @period)
    end

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
      @formed_data[query][row['report_date']] = if @weekly_mode && !@cumulative
        vals = row['value'].split(',')
        order = row['value_order'].split(',').map{|d| Date.parse(d) }
        [vals, order].transpose.sort_by{|e| e.last }.map {|e| e.first.to_i }
      else
        row['value'].to_i
      end
    end
  end

  # Calculates non-cumulative average
  # 
  # +data_array+ - array of values
  def calculate_noncumulative(data_array)
    data_row = []
    (data_array.size-1).downto(1) do |i|
      data_row[i] = (data_array[i] - data_array[i-1]) rescue nil
    end
    data_row[0] = nil
    data_row
  end

  def make_chart_series!
    @category_formatter ||= Proc.new {|original_category| original_category }
    @categories ||= @rollup_data_rows.map{|row| row['report_date']}.uniq

    @chart_series = @formed_data.map do |query, values|
      data_row = Array.new(@categories.size)
      values.each do |row_cat, val| #This should keep the order
        dest_cat = @category_formatter.call(row_cat)
        if idx = @categories.index(dest_cat)
          data_row[idx] = val
        end
      end
      unless @cumulative
        if @weekly_mode
          (data_row.size-1).downto(0) do |i|
            vals = calculate_noncumulative(data_row[i]).compact #data_row[i] is a sorted array produced by GROUP_CONCAT
            average = vals.sum.to_f / vals.size
            data_row[i] = (average.nil? || average.nan? || average.infinite?) ? nil : average.round.to_i
          end
        else
          data_row = calculate_noncumulative(data_row)
        end
      end
      s = {
        :name => query,
        :data => data_row
      }
      colorize!(s)
      s
    end
  end

  def make_calculations!
    obsolete_series_names = []
    @series_calculations.each do |calc|
      series_to_operate = calc[:series].map do |target_serie_name|
        @chart_series.select{|s| target_serie_name.casecmp(s[:name])==0 }.first  || throw("Unkonwn series - #{target_serie_name}")
      end
      obsolete_series_names += calc[:series].map(&:downcase)
      data_row_size = series_to_operate.map{|s| s[:data].size }.max
      data_row = Array.new(data_row_size) do |i|
        series_to_operate.inject(nil) do |accumulator, serie|
          CALC_OPS[calc[:op]].call(accumulator, serie[:data][i])
        end
      end
      new_serie = {
        :name => calc[:name],
        :data => data_row
      }
      colorize!(new_serie)
      @chart_series << new_serie
    end
    @chart_series.reject! { |s| obsolete_series_names.include?(s[:name].downcase) }
  end

  def humanize_series_names!
    @chart_series.each { |serie| serie[:name] = human_query_name(serie[:name]) }
    #@chart_series = @chart_series.sort_by{|s| s[:name] }
  end

  def human_query_name(query_name)
    HUMAN_QUERY_NAMES[query_name.downcase] || ( @humanize_unknown_series ? query_name.gsub('.', ' ').humanize : query_name )
  end

  def colorize!(serie)
    return if !@colorize || serie[:color]
    if serie[:type]
      serie[:color] = TYPE_COLORS[serie[:type]]
    elsif type = serie[:name].scan(/(#{TYPE_COLORS.keys.join('|')})/i).flatten.last
      serie[:color] = TYPE_COLORS[type.downcase.to_sym]
    end
  end

  
end