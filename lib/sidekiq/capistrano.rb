Capistrano::Configuration.instance.load do

  _cset(:sidekiq_default_hooks) { true }
  _cset(:sidekiq_cmd) { "#{fetch(:bundle_cmd, "bundle")} exec sidekiq" }
  _cset(:sidekiqctl_cmd) { "#{fetch(:bundle_cmd, "bundle")} exec sidekiqctl" }
  _cset(:sidekiq_timeout)   { 10 }
  _cset(:sidekiq_role)      { :app }
  _cset(:sidekiq_pid)       { "#{current_path}/tmp/pids/sidekiq.pid" }
  _cset(:sidekiq_processes) { 1 }
  _cset(:sidekiq_env)       { fetch(:rails_env, "production") }

  if fetch(:sidekiq_default_hooks)
    before "deploy:update_code", "sidekiq:quiet"
    after "deploy:stop",    "sidekiq:stop"
    after "deploy:start",   "sidekiq:start"
    before "deploy:restart", "sidekiq:restart"
  end

  namespace :sidekiq do
    desc "Quiet sidekiq (stop accepting new work)"
    task :quiet, :roles => lambda { fetch(:sidekiq_role) }, :on_no_matching_servers => :continue do
      run "RAILS_ENV=#{fetch(:sidekiq_env)} #{fetch(:bundle_cmd, "bundle")} exec rake \"sidekiq:quiet[#{fetch(:sidekiq_processes)},#{fetch(:sidekiq_pid)},#{fetch(:sidekiqctl_cmd)}]\""
    end

    desc "Stop sidekiq"
    task :stop, :roles => lambda { fetch(:sidekiq_role) }, :on_no_matching_servers => :continue do
      run "RAILS_ENV=#{fetch(:sidekiq_env)} #{fetch(:bundle_cmd, "bundle")} exec rake \"sidekiq:stop[#{fetch(:sidekiq_processes)},#{fetch(:sidekiq_pid)},#{fetch(:sidekiq_cmd)}]\""
    end

    desc "Start sidekiq"
    task :start, :roles => lambda { fetch(:sidekiq_role) }, :on_no_matching_servers => :continue do
      run "RAILS_ENV=#{fetch(:sidekiq_env)} #{fetch(:bundle_cmd, "bundle")} exec rake \"sidekiq:start[#{fetch(:sidekiq_processes)},#{fetch(:sidekiq_pid)},#{fetch(:sidekiqctl_cmd)},#{fetch(:sidekiqctl_timeout)}]\""
    end

    desc "Restart sidekiq"
    task :restart, :roles => lambda { fetch(:sidekiq_role) }, :on_no_matching_servers => :continue do
      stop
      start
    end

  end
end
