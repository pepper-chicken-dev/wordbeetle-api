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
end
