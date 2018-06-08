#
# FinancialSummary
#
# Summarizes transactions by day, week, and lifetime.
#
class FinancialSummary
  # TODO: refactor class methods to be DRY (there will of course be repetition)
  # TODO: refator into query object
  # MAYBE: move this class into a service folder?

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
    since_date = Transaction.arel_table[:created_at].gt(report_begins_at)
    @query = Transaction.where(user: user, amount_currency: currency.to_s.upcase)
    if report_begins_at
      @query = @query.where(since_date)
    end
  end

  def count(category)
    @query.where(category: category).count()
  end

  def amount(category)
    cents = @query.where(category: category).sum(:amount_cents)
    Money.new(cents, @currency)
  end
end