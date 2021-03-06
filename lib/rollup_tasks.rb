require 'zip/zip'

class RollupTasks
  TIME_ZONE = "Tijuana"
  # report intervals are in minutes
  QUARTER_HOURLY_REPORT_INTERVAL = 15
  HALF_HOURLY_REPORT_INTERVAL = 30
  HOURLY_REPORT_INTERVAL = 60
  DAILY_REPORT_INTERVAL = HOURLY_REPORT_INTERVAL * 24
  WEEKLY_REPORT_INTERVAL = DAILY_REPORT_INTERVAL * 7
  MONTHLY_REPORT_INTERVAL = DAILY_REPORT_INTERVAL * 30

  # the now times are here so we get
  # consistent times for our queries
  def self.set_now
    @@now = DateTime.now.in_time_zone(TIME_ZONE)
  end

  def self.now
    @@now
  end

  def self.pretty_time
    return now.strftime("%Y-%m-%d %I:%M:%S %p")
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
      db.execute("
INSERT INTO name_and_time(reported_at, query_name) select reported_at, query_name FROM
(SELECT DISTINCT reported_at FROM rollup_results WHERE span=#{span}) as t, (SELECT DISTINCT query_name FROM rollup_results WHERE span=#{span}) as q
      ")

      # output the headers which are the ordered query names
      headers = db.execute("SELECT distinct query_name FROM rollup_results WHERE span=#{span} ORDER BY query_name")
      return rollup_data if headers.count == 0
      out_row = ["Date"]
      headers.each do |header|
        name = header[0]
        out_row << name
      end
      rollup_data << out_row

      results_per_row = headers.count

      # now fetch the proper results for each date - basically expects the number of results
      # to match the number of headers for each date
      rows = db.execute("
SELECT n.reported_at, n.query_name, r.sum_value, r.span from rollup_results r
RIGHT OUTER JOIN name_and_time n ON r.query_name = n.query_name AND r.reported_at = n.reported_at AND r.span=#{span}
ORDER BY n.reported_at, n.query_name
      ")
      row_count = 0
      out_row = []
      rows.each do |row|
        # first of new row get the date
        out_row << "#{row[0].in_time_zone(TIME_ZONE).strftime("%Y-%m-%d %I:%M %p")}" if row_count % results_per_row == 0
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

  # return a small back trace limited to
  # limit specified or 5 lines by default
  # also adds exception message at top
  def self.small_back_trace(ex, lines = 5)
    result = ex.message + "\n"
    bt = ex.backtrace
    lines_left = lines
    bt.each do |line|
      if (lines_left > 0)
        result << line + "\n"
      end
      lines_left -= 1
    end

    return result
  end

  # run the sweep block specified
  # but log and eat any exception
  # so we continue on
  def self.protected_run
    begin
      yield
    rescue Exception => ex
      msg = small_back_trace(ex)
      puts msg
      Rails.logger.error(msg)
    end
  end

  def self.dump_file(path)
    Rails.logger.info("Dumping file:")
    f = File.open(path, "rb")
    f.lines.each do |line|
      Rails.logger.info line
    end
    f.close
  end

  # run the query to collect all results
  # and store in a temp csv file or optionally
  # into a zip file
  def self.create_csv(span, zip_it, base_file_name)
    t = Tempfile.new("ruzippy-#{Time.now.to_i}")
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

    t.flush
    t.rewind
    return t
  end

  # useful for sanity check on deployed server
  # check with span of 11111
  def self.test_run()
    set_now
    full_report_sweep(11111)
  end

  def self.full_report_sweep(span)
    puts "#{pretty_time}: Cron job report sweep"
    protected_run { UserSweep.full(span) }
    protected_run { AlbumSweep.full(span) }
    protected_run { PhotoSweep.full(span) }
    protected_run { EvtSweep.full(span) }
    protected_run { CohortSweep.full(span) }
    protected_run { GASweep.full(span) }
    protected_run { KFactorSweep.full(span) }
    protected_run { NonUsersSweep.full(span) }
  end

  # sweeps the final set for the sweep span
  # and writes out the results and uploads them to s3
  def self.daily_full_report_sweep
    set_now
    span = DAILY_REPORT_INTERVAL
    full_report_sweep(span)
  end

  def self.minimal_sweep
    set_now
    span = QUARTER_HOURLY_REPORT_INTERVAL
    protected_run { UserSweep.minimal(span) }
    protected_run { AlbumSweep.minimal(span) }
    protected_run { PhotoSweep.minimal(span) }
    protected_run { EvtSweep.minimal(span) }
    protected_run { CohortSweep.minimal(span) }
    protected_run { GASweep.minimal(span) }
  end

  def self.monthly_sweep
    set_now
    span = MONTHLY_REPORT_INTERVAL
    protected_run { CohortSweep.monthly(span) }
  end

  # call this manually to generate monthly
  # numbers for April
#  def self.monthly_fixup
#    # fake the date
#    @@now = DateTime.civil(2011, 5, 1, 6, 35).in_time_zone(TIME_ZONE)
#    span = MONTHLY_REPORT_INTERVAL
#    CohortSweep.monthly(span)
#  end

  def self.kind(span)
    case span
      when MONTHLY_REPORT_INTERVAL: "monthly"
      when WEEKLY_REPORT_INTERVAL: "weekly"
      when DAILY_REPORT_INTERVAL: "daily"
      when HOURLY_REPORT_INTERVAL: "hourly"
      when HALF_HOURLY_REPORT_INTERVAL: "half-hourly"
      when QUARTER_HOURLY_REPORT_INTERVAL: "quarter-hourly"
      else span.to_s
    end
  end
end

