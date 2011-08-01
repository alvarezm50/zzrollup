class CohortsDatasource
  include ActionView::Helpers::DateHelper

  attr_accessor :query_name_mask, :period, :categories, :category_formatter, :percent_view
  attr_reader :span, :span_code, :chart_series

  def initialize(opts = {})
    calc_now = opts.delete(:calculate_now) || false
    opts.each {|param, val| self.send("#{param}=", val) }
    calculate_chart if calc_now
  end

  def span=(val)
    @span = val.to_i
    @span_code = RollupTasks.kind(@span)

    @x_labels_format = case @span_code
      when 'monthly' then '%b 1, %Y'
      when 'daily', 'weekly' then '%Y-%m-%d'
      else '%Y-%m-%d %H:%i'
    end
    @weekly_mode = (@span_code=='weekly')
  end

  def weekly_mode?
    @weekly_mode
  end

  def chart_subtitle
    "#{@weekly_mode ? 'Weekly average' : @span_code.humanize}, #{distance_of_time_in_words(@period.first, @period.last)}"
  end

  def calculate_chart
    fetch_data!
    transform_data!
    make_chart_series!
  end

  XLS_FORMAT = {
    :series_names => Spreadsheet::Format.new(
       :bold => true,
       :bottom => true
    ),
    :categories => Spreadsheet::Format.new(
       :bold => true,
       :right => true,
       :horizontal_align => :right
    )
  }

  XLS_CELL_TYPE = {
    :float => Spreadsheet::Format.new( :number_format => '0.00' ),
    :percent => Spreadsheet::Format.new( :number_format => '0.00%' ),
  }

  def produce_xls(custom_series = nil)
    workbook = Spreadsheet::Workbook.new
    worksheet = workbook.create_worksheet(:name => 'Chart data')
    0.upto(@categories.size) { |i| worksheet.column(i).width = 15 }
    worksheet.row(0).default_format = XLS_FORMAT[:series_names]
    worksheet.column(0).default_format = XLS_FORMAT[:categories]
    worksheet.row(0).set_format(0, worksheet.default_format)

    series = custom_series || @chart_series
    series.each_with_index do |serie, serie_idx|
      worksheet.row(0)[1+serie_idx] = serie[:name]
    end
    @categories.each_with_index do |cat, cat_idx|
      worksheet.row(1+cat_idx)[0] = cat
      series.each_with_index do |serie, serie_idx|
        worksheet.row(1+cat_idx)[1+serie_idx] = serie[:data][cat_idx]
        worksheet.row(1+cat_idx).set_format(1+serie_idx, XLS_CELL_TYPE[:percent]) if @percent_view
      end
    end

    report_io = StringIO.new
    workbook.write(report_io)
    report_io.string
  end

  
protected
  def default_period
    case @span_code
      when 'monthly' then (6.months.ago..Time.now)
      when 'weekly' then (8.weeks.ago..Time.now)
      when 'daily' then (60.days.ago..Time.now)
      when 'hourly' then (4.days.ago..Time.now)
      when 'half-hourly' then (2.days.ago..Time.now)
      when 'quarter-hourly' then (1.day.ago..Time.now)
      else (30.days.ago..Time.now)
    end
  end

  def fetch_data!
    @period ||= default_period

    fields_to_select = []
    conditions = []
    group_by = []

    fields_to_select << "cohort"
    if @weekly_mode
      fields_to_select << "DATE_FORMAT(SUBDATE(`reported_at`, INTERVAL WEEKDAY(`reported_at`) DAY), '#{@x_labels_format}') AS report_date"
      fields_to_select << "ROUND(AVG(sum_value)) AS value"
      fields_to_select << "DATE_FORMAT(reported_at, '%v %x') AS weekyear"
      group_by << 'weekyear'
      conditions << RollupResult.public_sanitize_sql('sum_value > 0')
    else
      fields_to_select << "DATE_FORMAT(reported_at, '#{@x_labels_format}') AS report_date"
      fields_to_select << "MAX(sum_value) AS value"
      group_by << 'report_date'
    end
    
    group_by << 'cohort'
    
    conditions << RollupResult.public_sanitize_sql(:reported_at => @period)
    conditions << RollupResult.public_sanitize_sql([
      "cohort > 0 AND span = ? AND query_name LIKE ?",
      !@weekly_mode ? @span : RollupTasks::DAILY_REPORT_INTERVAL, @query_name_mask
    ])
    
    #rollup_data_rows = RollupResult.select(fields_to_select.join(',')).group(!@weekly_mode ? :report_date : :weekyear).group(:cohort).where(:reported_at => @period).where("cohort > 0 AND span = ? AND query_name LIKE '#{query_name_mask}'", !@weekly_mode ? @span : RollupTasks::DAILY_REPORT_INTERVAL).order(:report_date)
    sql = <<-SQL
      SELECT #{fields_to_select.join(',')} FROM `rollup_results` 
      WHERE (#{conditions.join(') AND (')}) GROUP BY #{group_by.join(',')} ORDER BY `reported_at` ASC
    SQL
    @rollup_data_rows = RollupResult.connection.select_all(sql)
  end

  def transform_data!
    @formed_data = {}
    @rollup_data_rows.each do |row|
      @formed_data[row['cohort']] ||= {}
      @formed_data[row['cohort']][row['report_date']] = row['value']
    end
  end
  
  def make_chart_series!
    @category_formatter ||= Proc.new {|cohort, original_category| original_category }
    
    @categories ||= @rollup_data_rows.map{|row| row['report_date']}.uniq

    @chart_series = @formed_data.map do |cohort, values|
      data_row = Array.new(@categories.size)
      values.each do |row_cat, val| #This should keep the order
        dest_cat = @category_formatter.call(cohort, row_cat)
        if idx = @categories.index(dest_cat)
          data_row[idx] = val.to_i
        end
      end
      cohort_beginning_date = CohortManager.cohort_beginning_date(cohort)
      {
        :beginning_date => cohort_beginning_date,
        :name => cohort_beginning_date.strftime("Cohort %b '%y"),
        :color => self.class.cohort_web_color(cohort_beginning_date),
        :data => data_row
      }
    end
    @chart_series
  end

  
  def self.cohort_web_color(cohort_beginning_date)
=begin
    base_table = [
      [69, 114, 167],
      [170, 70, 67],
      [137, 165, 78],
      [128, 105, 155],
      [61, 150, 174],
      [219, 132, 61],
      [128, 128, 255],
      [255, 128, 255],
      [128, 255, 0],
      [120, 0, 255],
      [128, 0, 128],
      [255, 128, 0]
    ]

    r,g,b = base_table[cohort_beginning_date.month-1]
    #TODO Still need to solve colors for next years
#    shift = (cohort_beginning_date.year-2000)*2
#    "#%02x%02x%02x" % [r, g, b].map{|c| (c+shift)>255 ? c-shift : c+shift }
    "#%02x%02x%02x" % [r, g, b]
=end

    months_colors = ["#4572A7", "#AA4643", "#89A54E", "#800000", "#006400", "#191970", "#8080FF", "#FF80FF", "#80FF00", "#7800FF", "#800080", "#FF8000"]
    months_colors[cohort_beginning_date.month-1]

  end


end