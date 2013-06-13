namespace "sidekiq" do

  sidekiq_cmd = "bundle exec sidekiq"
  sidekiqctl_cmd = "bundle exec sidekiqctl"
  sidekiq_processes = 1
  sidekiq_pid = "tmp/pids/sidekiq.pid"
  sidekiq_role = :app
  sidekiq_timeout = 10
  sidekiq_default_hooks = true

  def for_each_process(sidekiq_processes, sidekiq_pid, &block)
    sidekiq_processes.to_i.times do |idx|
      yield((idx == 0 ? "#{sidekiq_pid}" : "#{sidekiq_pid}-#{idx}"), idx)
    end
  end

  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet, [:sidekiq_processes, :sidekiq_pid, :sidekiqctl_cmd] do |task, args|
    args.with_defaults(sidekiq_processes: sidekiq_processes, sidekiq_pid: sidekiq_pid, sidekiqctl_cmd: sidekiqctl_cmd)

    for_each_process args.sidekiq_processes, args.sidekiq_pid do |pid_file, idx|
      if File.exists?(pid_file) && Process.kill(0, File.read(pid_file).to_i )
        `#{args.sidekiqctl_cmd} quiet #{pid_file}`
      else
        puts "Sidekiq is not running"
      end
    end
  end

  desc "Stop sidekiq"
  task :stop, [:sidekiq_processes, :sidekiq_pid, :sidekiqctl_cmd, :sidekiq_timeout] do |task, args|
    args.with_defaults(sidekiq_processes: sidekiq_processes, sidekiq_pid: sidekiq_pid, sidekiqctl_cmd: sidekiqctl_cmd, sidekiq_timeout: sidekiq_timeout)

    for_each_process args.sidekiq_processes, args.sidekiq_pid do |pid_file, idx|
      if File.exists?(pid_file) && Process.kill(0, File.read(pid_file).to_i )
        `#{args.sidekiqctl_cmd} stop #{pid_file} #{args.sidekiq_timeout}`
      else
        puts "Sidekiq is not running"
      end
    end
  end

  desc "Start sidekiq"
  task :start, [:sidekiq_processes, :sidekiq_pid, :sidekiq_cmd, :rails_env] do |task, args|
    args.with_defaults(sidekiq_processes: sidekiq_processes, sidekiq_pid: sidekiq_pid, sidekiq_cmd: sidekiq_cmd, rails_env: ENV["RAILS_ENV"] || "production")

    for_each_process args.sidekiq_processes, args.sidekiq_pid do |pid_file, idx|
      `nohup #{args.sidekiq_cmd} -e #{args.rails_env} -C config/sidekiq.yml -i #{idx} -P #{pid_file} >> log/sidekiq.log 2>&1 &`
    end
  end
end
