class CreatedSinceQuery
  # can accept any relation, and so is totally re-usable!
  def initialize(relation = nil, date)
    @relation = relation
    @date = date
  end

  def relation
    if @date
      since_date = Transaction.arel_table[:created_at].gt(@date)
      @relation = @relation.where(since_date)
    end

    @relation
  end
end
