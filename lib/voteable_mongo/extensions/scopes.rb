require 'voteable_mongo/voting'
require 'voteable_mongo/embedded_voting'
require 'voteable_mongo/integrations/mongoid'
require 'voteable_mongo/integrations/mongo_mapper'


module Mongo
  module Voteable
    module Extensions
      module Scopes
        extend ActiveSupport::Concern
        
        included do
          
          scope :voted_by, lambda { |voter|
            voter_id = Helpers.get_mongo_id(voter)
            where('$or' => [{ 'votes.up' => voter_id }, { 'votes.down' => voter_id }])
          }

          scope :up_voted_by, lambda { |voter|
            voter_id = Helpers.get_mongo_id(voter)
            where('votes.up' => voter_id)
          }

          scope :down_voted_by, lambda { |voter|
            voter_id = Helpers.get_mongo_id(voter)
            where('votes.down' => voter_id)
          }
          
        end
        
      end
    end
  end
end
