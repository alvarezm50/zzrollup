class BaseSweep
  def self.make_full_name(name, span, with_kind = false)
    if with_kind
      kind = RollupTasks.kind(span)
      return "#{name}.#{kind}"
    else
      return name
    end
  end

  # build the between clause
  def self.build_between(now, back_to)
    # the following builds a between clause in the to_s method
    " created_at #{(back_to..now).to_s(:db)}"
  end

  # perform the low level query and return the
  # result array
  def self.execute(db, span, query)
    now = RollupTasks.now
    # determine how far back to go
    back_to = now - ((span * 60) - 1).seconds

    # build the span condition in case the query wants it
    between_clause = build_between(back_to, now)

    # run the query passed
#    sql = query.call(between_clause)
    sql = query
    results = db.execute(sql)
    return results
  end

  # saves the results given into the
  # rollup table
  #
  # expects results to be passed in the form
  #
  # [['name', value], ...]
  #
  def self.save_results(results, span)
    results.each do |result|
      full_name = result[0]
      value = result[1]
      roll_result = RollupResult.create_result(full_name, span)

      roll_result.sum_value = value
      roll_result.save()
    end
  end


  # use this for dealing with simple count queries
  # does the query and handles storing the result
  def self.full_query(db, name, span, query)
    r = execute(db, span, query).first

    full_name = make_full_name(name, span)

    # get the result object
    roll_result = RollupResult.create_result(full_name, span)

    roll_result.sum_value = r[0]
    roll_result.save()
  end

  # this form handles a grouped by query where the first column
  # represents the name to append to base_name, and the second
  # contains the count
  def self.grouped_query(db, base_name, span, query, calc_totals = false, is_cohort = false)
    # run the query
    results = execute(db, span, query)

    # this form expects to see multiple result rows
    total = 0
    results.each do |r|
      cohort = is_cohort ? r[0] : -1
      suffix = r[0].to_s
      v = r[1]

      suffix = 'NULL' if suffix.nil? || suffix.empty?
      name = base_name.empty? ? suffix : "#{base_name}.#{suffix}"
      full_name = make_full_name(name, span)

      # get the result object
      roll_result = RollupResult.create_result(full_name, span, cohort)
      roll_result.sum_value = v
      total += v
      roll_result.save()
    end

    if calc_totals
      # get the result object
      full_name = "#{base_name}.all"
      roll_result = RollupResult.create_result(full_name, span)
      roll_result.sum_value = total
      roll_result.save()
    end

  end

end