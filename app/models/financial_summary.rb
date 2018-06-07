#
# FinancialSummary
#
# Summarizes transactions by day, week, and lifetime.
#
class FinancialSummary
  # TODO: refactor class methods to be DRY (there will of course be repetition)
  # TODO: refator into query object
  # TODO: move this class into a service folder

  def self.one_day(args)
    user = args[:user]
    currency = args[:currency]
    report_begins_at = Date.today
    new(user, currency, report_begins_at)
  end

  def self.seven_days(args)
    user = args[:user]
    currency = args[:currency]
    report_begins_at = Date.today - 7.days
    new(user, currency, report_begins_at)
  end

  def initialize(user, currency, report_begins_at)
    @currency = currency
    since_date = Transaction.arel_table[:created_at].gt(report_begins_at)
    @query = Transaction.where(user: user, amount_currency: currency.to_s.upcase)
                        .where(since_date)
  end

  def count(category)
    @query.where(category: category).count()
  end

  def amount(category)
    cents = @query.where(category: category).sum(:amount_cents)
    Money.new(cents, @currency)
  end
end