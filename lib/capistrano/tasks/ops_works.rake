require 'rake'
require 'capistrano/ops_works'
require 'erb'

namespace :opsworks do
  def opsworks
    Capistrano::OpsWorks::Connection.new(\
      :access_key_id => deploy_config['access_key_id'],
      :secret_access_key => deploy_config['secret_access_key']
    )
  end

  def set_deploy_config env
    puts "Loading [#{env}] environment"
    @deploy_config ||= YAML.load(ERB.new(File.read("config/deploy.yml")).result)[env]
    puts @deploy_config.inspect
  end

  def deploy_config
    @deploy_config
  end

  def deployment_ids
    { 
      :stack_id => deploy_config['stack_id'],
      :app_id => deploy_config['app_id']
    }
  end

  def get_git_log_info
    `git log --pretty=format:'%h %ae %s' --date=short -n1`
  end

  def start_deploy command_args={}
    ids = deployment_ids
    deploy_opts = {
      :command => {
        :name => 'deploy', 
        :args => command_args
      },
      :comment => get_git_log_info
    }
    opts = ids.merge(deploy_opts)

    opsworks.deploy(opts)
  end

  task :deploy, [:environment] do |task, args|
    environment = !args.environment.nil? ? args.environment : 'staging'
    set_deploy_config environment
    puts start_deploy
  end

  desc "Checks your app_id for validity"
  task :check do
    puts "app_id #{deploy_config['app_id']} is valid" if opsworks.check(deployment_ids)
  end

  desc "Displays deployment history for app_id"
  task :history, [:environment,:app_id]  do |t, args|
    set_deploy_config args.environment
    puts opsworks.history deploy_config['app_id']
  end

  task :verify, :deployment_id do |task, args|
    puts opsworks.verify args[:deployment_id]
  end
end

desc "Deploy to opsworks"
task :opsworks => ["opsworks:deploy"]
