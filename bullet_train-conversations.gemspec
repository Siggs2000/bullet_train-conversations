require_relative "lib/bullet_train/conversations/version"

Gem::Specification.new do |spec|
  spec.name = "bullet_train-conversations"
  spec.version = BulletTrain::Conversations::VERSION
  spec.authors = ["Andrew Culver"]
  spec.email = ["andrew.culver@gmail.com"]
  spec.homepage = "https://github.com/andrewculver/bullet_train-conversations"
  spec.summary = "Bullet Train Conversations"
  spec.description = spec.summary
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md", ".bt-link"]
  end

  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "bullet_train-super_scaffolding", "~> 1.0"
  spec.add_dependency "extended_email_reply_parser", "~> 0.5"

  spec.add_development_dependency "bullet_train", "~> 1.6.9"
  spec.add_development_dependency "bullet_train-themes", "~> 1.6.9"
  spec.add_development_dependency "bullet_train-themes-light", "~> 1.6.9"
  spec.add_development_dependency "factory_bot_rails", "~> 6.2"
  spec.add_development_dependency "minitest", "~> 5.1"
  spec.add_development_dependency "pg", "~> 1.3"
  spec.add_development_dependency "rails", "~> 7.0.0"
  spec.add_development_dependency "bullet_train-integrations-stripe", "~> 1.6.9"
  spec.add_development_dependency "minitest-rails", "~> 7.0"
  spec.add_development_dependency "turbo-rails", "~> 1.0"
end
