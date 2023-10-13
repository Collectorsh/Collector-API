namespace :mints do
  task update: :environment do
    system("/home/richard/.cargo/bin/metaboss -T 300 snapshot mints -c AHdb8jSpvqkJSYjnMT2TaR7zjV3qT3RkzD1QaeBn5odA --v2 -o /home/richard")
    file = File.open("/home/ubuntu/AHdb8jSpvqkJSYjnMT2TaR7zjV3qT3RkzD1QaeBn5odA_mint_accounts.json")
    data = file.read
    data = JSON.parse data
    data.each do |mint|
      TokenMint.where(mint: mint).first_or_create
    end
  end

  task count: :environment do
    users = {}
    TokenMint.all.each do |t|
      u = User.where("public_keys like '%#{t.owner}%'")
      next unless u.first

      users[u.first.username] ||= 0
      users[u.first.username] += 1
    end
    puts users.sort_by { |_key, value| value }.to_json
  end
end
