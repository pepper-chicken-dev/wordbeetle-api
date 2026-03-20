require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:wordbooks).dependent(:destroy) }
    it { is_expected.to have_one(:setting).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_uniqueness_of(:email).allow_nil }

    context "when provider is google" do
      subject { build(:user, provider: "google") }

      it { is_expected.to validate_presence_of(:provider_uid) }
      it { is_expected.to validate_uniqueness_of(:provider_uid).scoped_to(:provider) }
    end

    context "when provider is guest" do
      it "does not require provider_uid" do
        user = build(:user, :guest, provider_uid: nil)
        expect(user).to be_valid
      end
    end
  end

  describe "enum" do
    it { is_expected.to define_enum_for(:provider).with_values(google: "google", guest: "guest").backed_by_column_of_type(:string) }
  end

  describe "guest user validations" do
    context "when provider is guest" do
      it "requires guest_expires_at" do
        user = build(:user, :guest, guest_expires_at: nil)
        expect(user).not_to be_valid
        expect(user.errors[:guest_expires_at]).to include("can't be blank")
      end

      it "is valid with guest_expires_at set" do
        user = build(:user, :guest)
        expect(user).to be_valid
      end
    end

    context "when provider is google" do
      it "does not require guest_expires_at" do
        user = build(:user, guest_expires_at: nil)
        expect(user).to be_valid
      end
    end
  end

  describe "factory" do
    it "creates a valid google user" do
      expect(build(:user)).to be_valid
    end

    it "creates a valid guest user" do
      expect(build(:user, :guest)).to be_valid
    end
  end
end
