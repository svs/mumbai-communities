class TestMailer < ApplicationMailer
  def postmark_integration_test(email)
    @timestamp = Time.current.strftime("%B %d, %Y at %I:%M %p %Z")
    @environment = Rails.env

    mail(
      to: email,
      subject: "🏙️ Mumbai Communities - Postmark Integration Test",
      from: "noreply@mcgm-boundaries.com"
    )
  end
end