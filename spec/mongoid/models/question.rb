class Question
  include Mongoid::Document
  include Mongo::Voteable
  
  field :question

  embeds_many :answers

  voteable self, :up=>+1, :down=>-1, :index=>true
  
end