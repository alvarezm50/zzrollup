# this class manages related cohort content
class CohortManager
  IN_CLAUSE_MAX = 25000

  attr_accessor :name, :span, :date_first, :date_last, :current_cohort

  # this represents the beginning date of cohort 1
  def self.cohort_base
    @@cohort_base ||= DateTime.civil(2011,4)
  end

  # calculate the cohort number from the given date
  def self.cohort_from_date(curr)
    # move forward 1 month to include all of the current month
    curr = curr.in_time_zone("GMT")
    forward = curr >> 1
    f_y = forward.year
    f_m = forward.month
    b_y = cohort_base.year
    b_m = cohort_base.month

    # calculate the cohort number, < 1 is cohort 1
    cohort = (f_y - b_y) * 12 + (f_m - b_m)
    return cohort < 1 ? 1 : cohort
  end
  
  # return cohort beginning date from cohort number (reverse of cohort_from_date)
  def self.cohort_beginning_date(cohort)
    cohort_base + (cohort - 1).months
  end

  # return the cohort based on the current date
  def self.cohort_current
    return cohort_from_date(DateTime.now())
  end


  def initialize(name, span, first, last)
    # this set holds the user ids we care about
    # if nil we have no user ids to filter out
    @user_ids = nil
    self.date_first = "'#{first.in_time_zone("GMT").to_s(:db)}'"
    self.date_last = "'#{last.in_time_zone("GMT").to_s(:db)}'"
    self.current_cohort = CohortManager.cohort_from_date(last)
    self.span = span
    self.name = name
  end


  def ensure_user_ids
    @user_ids ||= Set.new
  end

  def add_user_id(id)
    ensure_user_ids
    @user_ids.add(id)
  end

  def match_user_id?(id)
    return true if @user_ids.nil?
    return @user_ids.include?(id)
  end

  # filter the counts based on the user id set
  # produces a new array of just the matched items
  # if the user id filter is nil we match all
  #
  # the form of the input data is expected to be:
  # [[user_id, cohort], ...]
  #
  # we sum up the count of matching user_ids into their
  # cohort bucket
  #
  def sum_cohorts(users)
    sums = []
    # initialize the expected number of cohorts
    (1..current_cohort).each do |cohort|
      sums[cohort] = 0
    end

    users.each do |user|
      user_id = user[0]
      cohort = user[1]
      sums[cohort] = 0 if sums[cohort].nil?
      if match_user_id?(user_id)
        sums[cohort] += 1
      end
    end

    return sums
  end

  # run the query and add the users found as filters
  # expects you to select and return only the user_ids
  def add_users_query(db, proc)
    # since we are running a query, no longer match all even if it returns nothing
    ensure_user_ids

    sql = proc.call(date_first, date_last)
    results = db.execute(sql)

    # this form expects to see multiple result rows
    results.each do |r|
      user_id = r[0].to_i
      add_user_id(user_id) unless user_id == 0
    end
  end

  # run the cohorts query, this expects you to return:
  # [[user_id, cohort],...]
  # user_id, cohort from the select and will be filtered
  # against any previous add_users_query calls to effectively
  # limit the results by filtering various conditions together
  #
  # once complete, we return with a single array that
  # contains the cohort counts in the given cohort array position
  # you should iterate assuming a start index of 1 up to the length
  #
  def cohorts_query_local_merge(db, proc)
    sql = proc.call(date_first, date_last)
    results = db.execute(sql)
    sums = sum_cohorts(results)
    save_sums(sums)
    return sums
  end

  # This form of query expects you to provide summarized results
  # When we run the query we expect to get back results of:
  # [[cohort, count], ...]
  # we then record the sums in the rollup result table
  def cohorts_query(db, proc)
    sums = []
    # initialize the expected number of cohorts
    (1..current_cohort).each do |cohort|
      sums[cohort] = 0
    end

    sql = proc.call(date_first, date_last)
    results = db.execute(sql)
    results.each do |r|
      cohort = r[0]
      sum = r[1]
      sums[cohort] = 0 if sums[cohort].nil?
      sums[cohort] += sum
    end

    save_sums(sums)
    return sums
  end

  # Run a cohorts_query derived from the current user_ids that
  # have been added formed into a set that can be used in
  # an IN clause.  We actually break the set up into multiple
  # parts in case we have a very large number of ids.  We then
  # sum the cohorts from the multiple calls, and report them
  #
  # the query must return results as
  # [[cohort, sum],...]
  #
  # This call is similar the to plain cohorts_query except it
  # filters against the user ids that have been added to the manager
  #
  def cohorts_query_in(db, proc)
    sums = []
    # initialize the expected number of cohorts
    (1..current_cohort).each do |cohort|
      sums[cohort] = 0
    end

    if !@user_ids.nil?
      # build our user ids
      total_ids = @user_ids.length
      count = 0
      stmt = ""
      @user_ids.each do |user_id|
        if count % IN_CLAUSE_MAX == 0
          stmt << "(#{user_id}"
        else
          stmt << ",#{user_id}"
        end
        count += 1
        if (count % IN_CLAUSE_MAX == 0) || (count == total_ids)
          # hit max batch size or last batch, submit the query
          stmt << ")"
          sql = proc.call(date_first, date_last, stmt)
          stmt = ""
          results = db.execute(sql)
          results.each do |r|
            cohort = r[0]
            sum = r[1]
            sums[cohort] = 0 if sums[cohort].nil?
            sums[cohort] += sum
          end
        end
      end
    end

    save_sums(sums)
    return sums
  end


  def save_sums(sums)
    total = 0
    (1...sums.count).each do |cohort|
      # get the result object
      cohort_name = "#{name}.#{cohort}"
      roll_result = RollupResult.create_result(cohort_name, span, cohort)

      sum = sums[cohort]
      total += sum
      roll_result.sum_value = sum

      roll_result.save()
    end

    # now the total for all
    cohort_name = "#{name}.all"
    roll_result = RollupResult.create_result(cohort_name, span)
    roll_result.sum_value = total
    roll_result.save()
  end

end