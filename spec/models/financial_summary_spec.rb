require 'rails_helper'

#
# Notes:
#
# normally I'd have two levels of nesting (and no more than that)
# and I would use a bunch of `let()` and `before`, etc.
# but this time I decided to refactor the tests using shared examples
#
# it ended up being a bit quicker to write and it's less nested feeling
#

shared_examples "reporting basics" do |method|
  it 'requires a user' do
    expect{FinancialSummary.send(method, currency: :usd)}.to raise_error(ArgumentError)
  end

  it 'requires currency' do
    expect{FinancialSummary.send(method, user: user)}.to raise_error(ArgumentError)
  end

  it 'respects the correct currency' do
    Timecop.freeze(Time.now) do
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(12.50, :cad))
    end

    subject = FinancialSummary.send(method, user: user, currency: :cad)

    expect(subject.amount(:deposit)).to eq(Money.from_amount(12.50, :cad))
    expect(subject.count(:deposit)).to eq(1)
  end

  it 'respects the correct user' do
    second_user = create(:user)

    Timecop.freeze(Time.now) do
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
      create(:transaction, user: second_user, category: :deposit, amount: Money.from_amount(12.50, :usd))
    end

    subject = FinancialSummary.send(method, user: user, currency: :usd)
    expect(subject.amount(:deposit)).to eq(Money.from_amount(2.12, :usd))
    expect(subject.count(:deposit)).to eq(1)
  end

  it 'respects the correct category' do
    Timecop.freeze(Time.now) do
      create(:transaction, user: user, category: :withdraw, amount: Money.from_amount(1.23, :usd))
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(12.50, :cad))
    end

    subject = FinancialSummary.send(method, user: user, currency: :usd)

    expect(subject.amount(:withdraw)).to eq(Money.from_amount(1.23, :usd))
    expect(subject.count(:withdraw)).to eq(1)
  end
end

describe FinancialSummary do
  let(:user) { create(:user) }

  it_behaves_like "reporting basics", :one_day
  it_behaves_like "reporting basics", :seven_days
  it_behaves_like "reporting basics", :lifetime

  it 'summarizes over one day' do
    Timecop.freeze(Time.now) do
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
    end

    Timecop.freeze(2.days.ago) do
      create(:transaction, user: user, category: :deposit)
    end

    subject = FinancialSummary.one_day(user: user, currency: :usd)
    expect(subject.count(:deposit)).to eq(2)
    expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :usd))
  end

  it 'summarizes over seven days' do
    Timecop.freeze(5.days.ago) do
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
    end

    Timecop.freeze(8.days.ago) do
      create(:transaction, user: user, category: :deposit)
    end

    subject = FinancialSummary.seven_days(user: user, currency: :usd)
    expect(subject.count(:deposit)).to eq(2)
    expect(subject.amount(:deposit)).to eq(Money.from_amount(12.12, :usd))
  end

  it 'summarizes over lifetime' do
    Timecop.freeze(30.days.ago) do
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(2.12, :usd))
      create(:transaction, user: user, category: :deposit, amount: Money.from_amount(10, :usd))
    end

    Timecop.freeze(8.days.ago) do
      create(:transaction, user: user, category: :deposit)
    end

    subject = FinancialSummary.lifetime(user: user, currency: :usd)
    expect(subject.count(:deposit)).to eq(3)
    expect(subject.amount(:deposit)).to eq(Money.from_amount(13.12, :usd))
  end
end
