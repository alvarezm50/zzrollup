module RollupData
  class UniversalDatasource
    include ActionView::Helpers::DateHelper

    include Humanization
    include Colorization
    include RowCalculation
    include Reporting

    attr_accessor :query_name_mask, :period, :categories, :category_formatter, :percent_view
    attr_reader :span, :span_code, :chart_series

    attr_accessor :whole_history, :queries_to_fetch, :series_calculations, :humanize_unknown_series, :cumulative, :colorize


    def initialize(opts = {})
      #Defaults
      @humanize_unknown_series = true
      @cumulative = true
      @colorize = false
      self.span = RollupTasks::DAILY_REPORT_INTERVAL
      #Setting attributes from opts
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


    def calculate_chart
      fetch_data!
      transform_data!
      make_chart_series!
      make_calculations! if @series_calculations
      humanize_series_names!
    end

    def chart_subtitle
      "#{@cumulative ? 'Cumulative' : 'Non-cumulative'}, on a #{@span_code} basis" # (#{@period.begin.strftime('%d %b %y')} - #{@period.end.strftime('%d %b %y')})"
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
              data_row[i].insert(0, data_row[i-1].last) if i>0
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


  end
end