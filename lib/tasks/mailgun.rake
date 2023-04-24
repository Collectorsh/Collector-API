namespace :mailgun do
  task test: :environment do
    message_params = {
      from: 'notify@collector.sh',
      to: 'richardfsr@gmail.com',
      subject: 'Auction ending soon',
      text: 'this is just a test'
    }
    MAILGUN.send_message 'notify.collector.sh', message_params
  end
end
