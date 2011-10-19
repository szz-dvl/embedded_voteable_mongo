require 'rubygems'
require 'bundler'
Bundler.setup

# TODO: Need better solution
if rand > 0.5
  puts 'Mongoid'
  require 'mongoid'
  models_folder = File.join(File.dirname(__FILE__), 'mongoid/models')
  Mongoid.configure do |config|
    name = 'voteable_mongo_test'
    host = 'localhost'
    config.master = Mongo::Connection.new.db(name)
    config.autocreate_indexes = true
  end
else
  puts 'MongoMapper'
  require 'mongo_mapper'
  models_folder = File.join(File.dirname(__FILE__), 'mongo_mapper/models')
  MongoMapper.database = 'voteable_mongo_test'
end


$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require 'voteable_mongo'
require 'rspec'
require 'rspec/autorun'

Dir[ File.join(models_folder, '*.rb') ].each { |file|
  puts file
  require file
  file_name = File.basename(file).sub('.rb', '')
  klass = file_name.classify.constantize
  if klass.respond_to?("embedded?") && klass.embedded?
    metadata = klass.relations.find{ |x,r| r.relation == Mongoid::Relations::Embedded::In}.try(:last)
    metadata.class_name.constantize.collection.drop unless metadata.nil?
  else
    klass.collection.drop
  end
}
