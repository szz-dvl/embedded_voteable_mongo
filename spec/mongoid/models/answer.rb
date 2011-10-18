require File.join(File.dirname(__FILE__), 'question')

class Answer
  include Mongoid::Document
  include Mongo::Voteable
  
  field :answer
  field :position, :type=>Integer

  embedded_in :question

  voteable self, :up=>+1, :down=>-1, :index=>true, :embedded=>true
  
end