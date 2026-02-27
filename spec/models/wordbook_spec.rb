require "rails_helper"

RSpec.describe Wordbook, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:words).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "factory" do
    it "creates a valid wordbook" do
      expect(build(:wordbook)).to be_valid
    end
  end
end
