require "rails_helper"

RSpec.describe Word, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:wordbook) }
    it { is_expected.to have_many(:meanings).dependent(:destroy) }
    it { is_expected.to have_many(:examples).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:spelling) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "enum" do
    it do
      is_expected.to define_enum_for(:status)
        .with_values(not_studied: "not_studied", hard: "hard", uncertain: "uncertain", easy: "easy")
        .backed_by_column_of_type(:string)
    end
  end

  describe "factory" do
    it "creates a valid word" do
      expect(build(:word)).to be_valid
    end
  end

  describe "status transitions" do
    let(:word) { create(:word) }

    it "defaults to not_studied" do
      expect(word).to be_not_studied
    end

    it "can be changed to hard" do
      word.hard!
      expect(word).to be_hard
    end

    it "can be changed to uncertain" do
      word.uncertain!
      expect(word).to be_uncertain
    end

    it "can be changed to easy" do
      word.easy!
      expect(word).to be_easy
    end
  end
end
