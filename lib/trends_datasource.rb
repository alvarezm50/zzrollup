class TrendsDatasource
  include ActionView::Helpers::DateHelper

  attr_accessor :query_name_mask, :period, :categories, :category_formatter, :percent_view
  attr_reader :span, :span_code, :chart_series

  def initialize(opts = {})
    calc_now = opts.delete(:calculate_now) || false
    opts.each {|param, val| self.send("#{param}=", val) }
    calculate_chart if calc_now
  end

  def chart_subtitle
    "#{@weekly_mode ? 'Weekly average' : @span_code.humanize}, #{distance_of_time_in_words(@period.first, @period.last)}"
  end

  def calculate_chart
    fetch_data!
    #make_chart_series!
    @chart_series = @rollup_data_rows
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
    @category_formatter ||= Proc.new {|original_category| original_category }
    
    @categories ||= @rollup_data_rows.map{|row| row['report_date']}.uniq

    @chart_series = @formed_data.map do |cohort, values|
      data_row = Array.new(@categories.size)
      values.each do |row_cat, val| #This should keep the order
        dest_cat = @category_formatter.call(row_cat)
        if idx = @categories.index(dest_cat)
          data_row[idx] = val.to_i
        end
      end
      data_row
    end
    @chart_series
  end

  
end