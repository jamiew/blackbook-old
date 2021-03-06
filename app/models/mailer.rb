class Mailer < ActionMailer::Base
  default_url_options[:host] = '000000book.com'
  default from: '000000book <no-reply@000book.com>'

  def password_reset_instructions(user)
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail(to: user.email, subject: "Password Reset Instructions")
  end

  def signup_notification(user)
    @user = user
    @settings_url = settings_url
    @profile_url = user_url(user)
    mail(to: user.email, subject: "Your account registration info")
  end

end
