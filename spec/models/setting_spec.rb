require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:hard_interval) }
    it { is_expected.to validate_presence_of(:uncertain_interval) }
    it { is_expected.to validate_presence_of(:easy_interval) }
  end

  describe 'custom validation: intervals_must_be_positive' do
    let(:user) { create(:user) }

    it 'is valid with positive durations' do
      setting = build(:setting, user: user)
      expect(setting).to be_valid
    end

    it 'is invalid with zero duration' do
      setting = build(:setting, user: user, hard_interval: 0.days)
      expect(setting).not_to be_valid
      expect(setting.errors[:hard_interval]).to include('must be a positive interval')
    end
  end

  describe 'factory' do
    it 'creates a valid setting' do
      expect(build(:setting)).to be_valid
    end
  end

  describe '.default' do
    subject(:default_setting) { described_class.default }

    it 'returns a DefaultSetting with hard_interval of 1 day' do
      expect(default_setting.hard_interval).to eq(1.day)
    end

    it 'returns a DefaultSetting with uncertain_interval of 3 days' do
      expect(default_setting.uncertain_interval).to eq(3.days)
    end

    it 'returns a DefaultSetting with easy_interval of 7 days' do
      expect(default_setting.easy_interval).to eq(7.days)
    end

    it 'returns an empty hash for as_json' do
      expect(default_setting.as_json).to eq({})
    end
  end
end
