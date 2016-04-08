# -*- encoding: utf-8 -*-
# stub: voteable_mongo 0.9.3 ruby lib

Gem::Specification.new do |s|
  s.name = "voteable_mongo"
  s.version = "1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Alex Nguyen"]
  s.date = "2015-03-12"
  s.description = "Add up / down voting ability to Mongoid and MongoMapper documents. Optimized for speed by using only ONE request to MongoDB to validate, update, and retrieve updated data."
  s.email = ["alex@vinova.sg"]
  s.files = [".gitignore", ".rvmrc", ".watchr", "CHANGELOG.rdoc", "Gemfile", "README.rdoc", "Rakefile", "TODO", "lib/voteable_mongo.rb", "lib/voteable_mongo/embedded_voting.rb", "lib/voteable_mongo/extensions/embedded_scopes.rb", "lib/voteable_mongo/extensions/scopes.rb", "lib/voteable_mongo/helpers.rb", "lib/voteable_mongo/integrations/mongo_mapper.rb", "lib/voteable_mongo/integrations/mongoid.rb", "lib/voteable_mongo/railtie.rb", "lib/voteable_mongo/railties/database.rake", "lib/voteable_mongo/tasks.rb", "lib/voteable_mongo/version.rb", "lib/voteable_mongo/voteable.rb", "lib/voteable_mongo/voter.rb", "lib/voteable_mongo/voting.rb", "spec/.rspec", "spec/mongo_mapper/models/category.rb", "spec/mongo_mapper/models/comment.rb", "spec/mongo_mapper/models/post.rb", "spec/mongo_mapper/models/user.rb", "spec/mongoid/models/answer.rb", "spec/mongoid/models/category.rb", "spec/mongoid/models/comment.rb", "spec/mongoid/models/post.rb", "spec/mongoid/models/question.rb", "spec/mongoid/models/user.rb", "spec/spec_helper.rb", "spec/voteable_mongo/tasks_spec.rb", "spec/voteable_mongo/voteable_spec.rb", "spec/voteable_mongo/voter_spec.rb", "voteable_mongo.gemspec"]
  s.homepage = "https://github.com/vinova/voteable_mongo"
  s.rubyforge_project = "voteable_mongo"
  s.rubygems_version = "2.4.6"
  s.summary = "Add up / down voting ability to Mongoid and MongoMapper documents"
  s.test_files = ["spec/mongo_mapper/models/category.rb", "spec/mongo_mapper/models/comment.rb", "spec/mongo_mapper/models/post.rb", "spec/mongo_mapper/models/user.rb", "spec/mongoid/models/answer.rb", "spec/mongoid/models/category.rb", "spec/mongoid/models/comment.rb", "spec/mongoid/models/post.rb", "spec/mongoid/models/question.rb", "spec/mongoid/models/user.rb", "spec/spec_helper.rb", "spec/voteable_mongo/tasks_spec.rb", "spec/voteable_mongo/voteable_spec.rb", "spec/voteable_mongo/voter_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<mongoid>, ["~> 2.0"])
      s.add_development_dependency(%q<mongo_mapper>, ["~> 0.9"])
      s.add_development_dependency(%q<bson_ext>, ["~> 1.4"])
    else
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<mongoid>, ["~> 2.0"])
      s.add_dependency(%q<mongo_mapper>, ["~> 0.9"])
      s.add_dependency(%q<bson_ext>, ["~> 1.4"])
    end
  else
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<mongoid>, ["~> 2.0"])
    s.add_dependency(%q<mongo_mapper>, ["~> 0.9"])
    s.add_dependency(%q<bson_ext>, ["~> 1.4"])
  end
end
