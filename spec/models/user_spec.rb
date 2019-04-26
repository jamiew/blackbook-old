require 'rails_helper'

RSpec.describe User, type: :model do

  it "should create" do
    user = FactoryBot.build(:user)
    user.save!
  end

  it "should fail without a login" do
    lambda { FactoryBot.create(:user, login: '') }.should raise_error
  end

  it "should fail without an email" do
    lambda { FactoryBot.create(:user, email: '') }.should raise_error
  end

  describe "#deliver_password_reset_instructions!" do
    let(:user){ FactoryBot.create(:user) }

    it "sends an email" do
      expect {
        user.deliver_password_reset_instructions!
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "calls user.reset_perishable_token!" do
      user.should_receive(:reset_perishable_token!)
      user.deliver_password_reset_instructions!
    end
  end

  describe "#reset_perishable_token!" do
    let(:user){ FactoryBot.create(:user) }

    it "changes the user's perishable token" do
      user.perishable_token.should_not be_blank
      expect {
        user.deliver_password_reset_instructions!
      }.to change(user, :perishable_token)
    end
  end

  describe "UTF-8 exceptions" do
    let(:body){ "hello joel\255".force_encoding('UTF-8') }

    def replace_name(body, name)
      body.gsub(/joel/, name)
    end

    def replace_name_safe(body, name)
      body.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(/joel/, name)
    end

    it "raises an exception if we use the unsafe method" do
      lambda { replace_name(body, 'hank') }.should raise_error(ArgumentError)
    end

    it "works if we use the safe method" do
      lambda { replace_name_safe(body, 'hank') }.should_not raise_error(ArgumentError)
      replace_name_safe(body, 'hank').should eq "hello hank"
    end
  end

end
