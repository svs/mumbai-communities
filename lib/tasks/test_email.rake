namespace :email do
  desc "Send test email to verify Postmark integration"
  task test: :environment do
    puts "Sending test email via Postmark..."

    begin
      TestMailer.postmark_integration_test("svs@svs.io").deliver_now
      puts "✓ Test email sent successfully!"
      puts "Check svs@svs.io for the test email from Mumbai Communities"
    rescue => e
      puts "✗ Failed to send test email: #{e.message}"
      puts e.backtrace.first(5)
    end
  end
end