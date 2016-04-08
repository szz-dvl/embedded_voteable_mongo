require 'voteable_mongo/voting'
require 'voteable_mongo/embedded_voting'
require 'voteable_mongo/integrations/mongoid'
require 'voteable_mongo/integrations/mongo_mapper'


module Mongo
  module Voteable
    module Extensions
      module EmbeddedScopes
        extend ActiveSupport::Concern
        
        included do
          
          #HISTORIC!!
          
          # scope :voted_by, lambda { |voter|
          #   voter_id = Helpers.get_mongo_id(voter)
          #   Rails.logger.info("class is #{voteable_parent_class}")
          #   voteable_parent_class.where('$or' => [{ "#{voteable_embedded_collection_name}.votes.up" => voter_id },
          #                                           { "#{voteable_embedded_collection_name}.votes.down" => voter_id }])
          # }
          # 
          # scope :up_voted_by, lambda { |voter|
          #   voter_id = Helpers.get_mongo_id(voter)
          #   voteable_parent_class.where("#{voteable_embedded_collection_name}.votes.up" => voter_id)
          # }
          # 
          # scope :down_voted_by, lambda { |voter|
          #   voter_id = Helpers.get_mongo_id(voter)
          #   voteable_parent_class.where("#{voteable_embedded_collection_name}.votes.down" => voter_id)
          # }
          
        end
        
        module ClassMethods
          #will work only for collections embeded 1 level down.
          def voted_by(voter)

            voter_id = Helpers.get_mongo_id(voter)
            voteable_parent_class.or({ "#{voteable_embedded_collection_name}.votes.up" => voter_id }, { "#{voteable_embedded_collection_name}.votes.down" => voter_id })

          end

          def up_voted_by(voter)
      
            voter_id = Helpers.get_mongo_id(voter)
            voteable_parent_class.where("#{voteable_embedded_collection_name}.votes.up" => voter_id) 
            
          end

          def down_voted_by(voter)
         
            voter_id = Helpers.get_mongo_id(voter)
            voteable_parent_class.where("#{voteable_embedded_collection_name}.votes.down" => voter_id)  
            
          end
          
        end
        
      end
    end
  end
end
