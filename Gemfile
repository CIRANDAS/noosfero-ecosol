source "https://rubygems.org"
gem 'rails',                    '~> 3.2.19'
gem 'fast_gettext',             '~> 0.6.8'
gem 'acts-as-taggable-on',      '~> 3.0.2'
gem 'rails_autolink',           '~> 1.1.5'
gem 'RedCloth',                 '~> 4.2.9'
gem 'ruby-feedparser',          '~> 0.7'
gem 'daemons',                  '~> 1.1.5'
gem 'nokogiri',                 '~> 1.5.5'
gem 'rake', :require => false
gem 'rest-client',              '~> 1.6.7'
gem 'exception_notification',   '~> 4.0.1'
gem 'locale',                   '2.0.9' # 2.1.0 has a problem with memoizable
gem 'gettext',                  '~> 2.2.1', :require => false, :group => :development

platform :ruby do
  gem 'pg',                     '~> 0.13.2'
  gem 'rmagick',                '~> 2.13.1'
  gem 'thin'
end
platform :jruby do
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'rmagick4j'
end

gem 'eita-jrails', path: 'vendor/plugins/eita-jrails'

gem 'unicode'

gem 'premailer-rails'

gem 'therubyracer', :platforms => :ruby
gem 'uglifier', '>= 1.0.3'
gem 'sass'
gem 'sass-rails'

group :production do
  gem 'dalli', '~> 2.7.0'
  gem 'unicorn'
  gem 'unicorn-worker-killer'
  gem 'rack-cache'
end

group :test do
  gem 'rspec',                  '~> 2.10.0'
  gem 'rspec-rails',            '~> 2.10.1'
  gem 'mocha',                  '~> 1.1.0', :require => false
end

group :cucumber do
  gem 'cucumber-rails',         '~> 1.0.6', :require => false
  gem 'capybara',               '~> 2.1.0'
  gem 'cucumber',               '~> 1.0.6'
  gem 'database_cleaner',       '~> 1.2.0'
  gem 'selenium-webdriver',     '~> 2.39.0'
end

# include plugin gemfiles
Dir.glob(File.join('config', 'plugins', '*')).each do |plugin|
  plugin_gemfile = File.join(plugin, 'Gemfile')
  eval File.read(plugin_gemfile) if File.exists?(plugin_gemfile)
end
