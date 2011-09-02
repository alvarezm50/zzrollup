module RollupData
  module Reporting

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

  end
end
