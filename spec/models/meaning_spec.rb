require "rails_helper"

RSpec.describe Meaning, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:word) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:display_order) }
    it { is_expected.to validate_numericality_of(:display_order).only_integer.is_greater_than(0) }
  end

  describe "factory" do
    it "creates a valid meaning" do
      expect(build(:meaning)).to be_valid
    end
  end
end
