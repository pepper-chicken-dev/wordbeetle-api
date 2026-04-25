require 'rails_helper'

RSpec.describe Meaning, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:word) }
    it { is_expected.to have_many(:examples).dependent(:destroy) }
    it { is_expected.to accept_nested_attributes_for(:examples) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:definition) }
    it { is_expected.to validate_length_of(:definition).is_at_most(1000) }
    it { is_expected.to validate_presence_of(:display_order) }
    it { is_expected.to validate_numericality_of(:display_order).only_integer.is_greater_than(0) }
  end

  describe 'factory' do
    it 'creates a valid meaning' do
      expect(build(:meaning)).to be_valid
    end
  end
end
