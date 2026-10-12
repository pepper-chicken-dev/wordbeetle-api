require 'rails_helper'

RSpec.describe 'Database seeds' do # rubocop:disable RSpec/DescribeClass -- Testing a seed script, not a class.
  let(:seed_path) { Rails.root.join('db/seeds.rb') }

  it 'creates examples associated with the intended meanings and can run again' do
    2.times { load seed_path }

    expect(Example.count).to eq(4)
    expect(Meaning.count).to eq(4)
    expect(User.count).to eq(2)
    expect(Example.find_by!(sentence: 'I like apples.').meaning.definition).to eq('りんご')
    expect(Example.find_by!(sentence: 'This is a red apple.').meaning.definition).to eq('りんご')
    expect(Example.find_by!(sentence: 'I read a book every day.').meaning.definition).to eq('本')
    expect(Example.find_by!(sentence: 'We need to negotiate the terms.').meaning.definition).to eq('交渉する')
  end

  it 'preserves existing data and creates no demo data in production' do
    create(:example)
    models = [User, Setting, Wordbook, Word, Meaning, Example]
    original_ids = models.map { |model| model.order(:id).pluck(:id) }
    allow(Rails.env).to receive(:production?).and_return(true)

    load seed_path

    expect(models.map { |model| model.order(:id).pluck(:id) }).to eq(original_ids)
  end

  it 'rolls back deletion and partial inserts when seeding fails' do
    user = create(:user)
    allow(Example).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect { load seed_path }.to raise_error(ActiveRecord::RecordInvalid)

    expect(User.find(user.id)).to eq(user)
    expect(User.where(email: ['test@example.com', 'demo@example.com'])).to be_empty
  end
end
