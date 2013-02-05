class AppBuilder < Rails::AppBuilder
  def readme
    create_file "README.md", "TODO"
  end

  def config
    super

    create_file "config/deploy.rb" do
      <<-DEPLOY.gsub /^ */, ''
        require 'basics/capistrano'
        require 'delayed/recipes'
        load 'deploy/assets'
        require 'flowdock/capistrano'

        require './config/boot'
        require 'airbrake/capistrano'

        set :flowdock_project_name, '#{app_name}'
        set :flowdock_deploy_tags, ['#{app_name}', 'deploy']
        set :flowdock_api_token, ['d859aab2f418cfcd72ea19c7a7448a15']

        set :stages, %w(production staging)
        set :app_name, '#{app_name}'
        set :rvm_ruby_string, '1.9.3-p194'
        set :rvm_install_with_sudo, true
        set :user, 'root'"
      DEPLOY
    end
  end

  def leftovers
    # root controller
    if yes? "HomeController erstellen? [yes/no]"
      name = ask("Wie soll er heißen?").underscore
      generate :controller, "#{name} index"
      route "root to: '#{name}\#index'"
      remove_file "public/index.html"
    end

    # git
    git :init
    append_file ".gitignore", "config/database.yml"
    append_file ".gitignore", ".idea"
    git add: ".", commit: "-m 'initial commit'"

    #gems
    @generator.gem 'twitter-bootstrap-rails'
    @generator.gem 'devise'
    @generator.gem 'simple_form'
    @generator.gem 'inherited_resources'
    @generator.gem 'airbrake'
    @generator.gem 'newrelic_rpm'

    @generator.gem 'basics', git: 'git://github.com/rubberandglue/basics'

    gem_group :development do
      gem 'better_errors'
    end

    gem_group :production, :staging do
      gem 'mysql2'
    end

    run 'bundle install'
    generate 'bootstrap:layout application fluid -f'
    generate 'simple_form:install --bootstrap'
    generate 'devise:install'

    # application.rb
    insert_into_file "config/application.rb", "    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'models', '*.{rb,yml}').to_s]\n    config.i18n.default_locale = :de\n", :after => "# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.\n"
  end
end