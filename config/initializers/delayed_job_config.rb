# config/initializers/delayed_job_config.rb
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 10
Delayed::Worker.max_attempts = 1
Delayed::Worker.max_run_time = 30.seconds
Delayed::Worker.read_ahead = 3
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = true
Delayed::Worker.raise_signal_exceptions = :term
# Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
