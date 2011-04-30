require 'zip/zip'

class RollupTasks
  # report intervals are in minutes
  DAILY_REPORT_INTERVAL = 1440
  HOURLY_REPORT_INTERVAL = 60
  QUARTER_HOURLY_REPORT_INTERVAL = 15

  # the now times are here so we get
  # consistent times for our queries
  def self.set_now
    @@now = DateTime.now
  end

  def self.now
    @@now
  end

  def self.pretty_time
    return DateTime.now.strftime("%Y-%m-%d %I:%M:%S %p")
  end

  # gather everything into an array of arrays
  # the first row has the headers and the rest
  # contain data.  We do this because we have
  # multiple ways we might want to format this
  # data and the logic to put it together is complex
  # so we want to keep it all in one place
  def self.rollup_raw_data(span)
    rollup_data = []
    RollupResult.transaction do
      db = RollupResult.connection

      # prep the cartesian product of times and query names
      # we use this to ensure the data always lines up even
      # when we have missing results
      db.execute("DELETE FROM name_and_time")
      db.execute("INSERT INTO name_and_time(reported_at, query_name) select reported_at, query_name from (select distinct reported_at from rollup_results) as t, (select distinct query_name from rollup_results) as q")

      # output the headers which are the ordered query names
      headers = db.execute("SELECT distinct query_name FROM rollup_results ORDER BY query_name")
      return rollup_data if headers.count == 0
      out_row = ["Date"]
      headers.each do |header|
        out_row << header[0]
      end
      rollup_data << out_row

      results_per_row = headers.count

      # now fetch the proper results for each data - basically expects the number of results
      # to match the number of headers for each date
      rows = db.execute("SELECT n.reported_at, n.query_name, r.sum_value, r.span from rollup_results r " +
                        "RIGHT OUTER JOIN name_and_time n ON r.query_name = n.query_name AND r.reported_at = n.reported_at AND r.span=#{span} " +
                        "ORDER BY n.reported_at, n.query_name"
            )
      row_count = 0
      out_row = []
      rows.each do |row|
        # first of new row get the date
        out_row << "#{row[0].in_time_zone("Tijuana").strftime("%Y-%m-%d %I:%M %p")}" if row_count % results_per_row == 0
        ct = row[2].to_s
        out_row << ct   # can be a nil value if missing
        row_count += 1
        if (row_count % results_per_row == 0)
          # hit the end of a line
          rollup_data << out_row
          out_row = []
        end
      end
    end
    return rollup_data
  end

  def self.stream_csv(span, out)
    rows = rollup_raw_data(span)

    rows.each do |row|
      out << row.join(',')
      out << "\n"
    end
  end

  # run the query to collect all results
  # and store in a temp csv file or optionally
  # into a zip file
  def self.create_csv(span, zip_it, base_file_name)
    t = Tempfile.new("knuckknuck-#{Time.now.to_i}-#{rand(999999999)}")
    if zip_it
      # want the result zipped
      Zip::ZipOutputStream.open(t.path) do |zos|
        zos.put_next_entry("#{base_file_name}.csv")
        stream_csv(span, zos)
      end
    else
      # just plain file
      stream_csv(span, t)
    end

    t.rewind
    return t
  end

  def self.full_report_sweep(span)
    puts "#{pretty_time}: Cron job report sweep"
    UserSweep.full(span)
    AlbumSweep.full(span)
    PhotoSweep.full(span)
    EvtSweep.full(span)
  end

  # sweeps the final set for the sweep span
  # and writes out the results and uploads them to s3
  def self.daily_full_report_sweep
    set_now
    span = DAILY_REPORT_INTERVAL
    full_report_sweep(span)
  end

  def self.hourly_full_report_sweep
    set_now

    full_report_sweep(QUARTER_HOURLY_REPORT_INTERVAL)
  end


  def self.kind(span)
    case span
      when 1440: "daily"
      when 60: "hourly"
      when 30: "half-hourly"
      when 15: "quarter-hourly"
      else span.to_s
    end
  end
end

