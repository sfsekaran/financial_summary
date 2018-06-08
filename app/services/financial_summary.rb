#
# FinancialSummary
#
# Summarizes transactions by day, week, and lifetime.
#
class FinancialSummary
  def self.one_day(user:, currency:)
    report_begins_at = Date.today
    new(user, currency, report_begins_at)
  end

  def self.seven_days(user:, currency:)
    report_begins_at = Date.today - 7.days
    new(user, currency, report_begins_at)
  end

  def self.lifetime(user:, currency:)
    new(user, currency, nil)
  end

  def initialize(user, currency, report_begins_at)
    @currency = currency
    @query = Transaction.where(user: user, amount_currency: currency.to_s.upcase)
    @query = CreatedSinceQuery.new(@query, report_begins_at).relation
  end

  def count(category)
    @query.where(category: category).count()
  end

  def amount(category)
    cents = @query.where(category: category).sum(:amount_cents)
    Money.new(cents, @currency)
  end
end