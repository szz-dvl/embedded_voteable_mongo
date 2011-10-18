module Mongo
  module Voteable
    module Integrations
      module Mongoid
        extend ActiveSupport::Concern

        included do
          field :votes, :type => Hash, :default => DEFAULT_VOTES

          class << self
            alias_method :voteable_index, :index
          end
        end
        
        module ClassMethods
          
          def voteable_relation(class_name)
            relations.find{ |x, r| r.class_name == class_name }.try(:last)
          end

          def voteable_collection
            if self.embedded?
              metadata = relations.find{ |x,r| r.relation.to_s == "Mongoid::Relations::Embedded::In"}.try(:last)
              metadata.class_name.constantize.collection.master.collection unless metadata.nil?
            else 
              collection.master.collection
            end
          end

          def voteable_foreign_key(metadata)
            metadata.foreign_key.to_s
          end
          
          def voteable_embedded_collection_name
            @voteable_embedded_collection_name ||= self.name.underscore.pluralize
          end
          
          def voteable_parent_class
            metadata = self.voteable_parent_metadata
            metadata.class_name.constantize if metadata
          end
          
          def voteable_parent_metadata
            relations.find{ |x,r| r.relation.name == "Mongoid::Relations::Embedded::In"}.try(:last)
          end
          
          def voteable_parent_key_name
            @voteable_parent_key_name ||= begin
              relation_metadata = self.voteable_parent_metadata
              relation.key if relation_metadata
            end
          end
        end
      end
    end
  end
end
