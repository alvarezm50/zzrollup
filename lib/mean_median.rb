module MeanMedian

  def mean
    self.inject(:+) / self.size.to_f
  end

  def median
    mid = self.size / 2
    [self[mid], self[-mid] ].mean
  end

end