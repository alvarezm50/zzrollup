module RollupData
  module RowCalculation
    
    CALC_OPS = {
      :sum => Proc.new do |collector, element|
        (collector||0) + (element||0)
      end,

      :div => Proc.new do |collector, element|
        res = collector.nil? ? element.to_f : (collector / element ) rescue nil
        (res.nil? || res.nan? || res.infinite?) ? nil : res
      end
    }

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

    def make_calculations!
      obsolete_series_names = []
      @series_calculations.each do |calc|
        series_to_operate = calc[:series].map do |target_serie_name|
          @chart_series.select{|s| target_serie_name.casecmp(s[:name])==0 }.first || throw("Unkonwn serie - #{target_serie_name}")
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

  end
end
