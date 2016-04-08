# -*- coding: utf-8 -*-
module Mongo
  module Voteable
    module EmbeddedVoting
      extend ActiveSupport::Concern
      
      module ClassMethods

        # Make a vote on an object of this class
        #
        # @param [Hash] options a hash containings:
        #   - :votee_id: the votee document id
        #   - :voter_id: the voter document id
        #   - :value: :up or :down
        #   - :revote: if true change vote vote from :up to :down and vise versa
        #   - :unvote: if true undo the voting
        # 
        # @return [votee, false]
        
        def vote(options)

          validate_and_normalize_vote_options(options)
          options[:voteable] = VOTEABLE[name][name]
          
          if options[:voteable]
            query, update = if options[:revote]
                              revote_query_and_update(options)
                            elsif options[:unvote]
                              unvote_query_and_update(options)
                            else
                              new_vote_query_and_update(options)
                            end
                        
            key = options[:votee].__metadata.key.to_s
            parent = options[:votee]._parent
            
            begin
              #Check if user can vote on the entity
              doc = query.nil? ? nil : parent.send("#{key}").and(query).first
              
            rescue Moped::Errors::OperationFailure
              doc = nil 
            end  
            
         
            #Don't know a better syntax for this, defining in the parent model "accept_nested_attriburtes" (for hashes??) for votee class may simplify the block
            if doc
              
            
              new_vals = {}
              named_attributes = key + '_attributes'
              
              if ! update[:push].nil?
                if ! update[:push][:votes_up].nil?
                  new_vals["up"] = doc.votes["up"] << update[:push][:votes_up]
                end
                
                if ! update[:push][:votes_down].nil?
                  new_vals["down"] = doc.votes["down"] << update[:push][:votes_down]
                end
              end
              
              if ! update[:pull].nil?
                if ! update[:pull][:votes_up].nil?
                  new_vals["up"] = doc.votes["up"] - [update[:pull][:votes_up]]
                end
                
                if ! update[:pull][:votes_down].nil?
                  new_vals["down"] = doc.votes["down"] - [update[:pull][:votes_down]] 
                end
              end
              
              if ! update[:down_count].nil?
                new_vals["down_count"] = doc.votes["down_count"] + update[:down_count] 
              end
              
              if ! update[:up_count].nil?
                new_vals["up_count"] = doc.votes["up_count"] + update[:up_count]
              end
              
              if ! update[:count].nil?
                new_vals["count"] = doc.votes["count"] + update[:count]
              end
              
              if ! update[:point].nil?
                new_vals["point"] = doc.votes["point"] + update[:point]
              end
              
              
              updated = doc.votes.merge(new_vals)
              
              if parent.update_attributes({ named_attributes: {"0" => { _id: options[:votee].id, votes: Marshal.load(Marshal.dump(updated)) }}})
                options[:votee]
              else
                false
              end
              
            else
              #User trying to "overvote" on an entity
              false
            end
          end
        end

        
        private
          def validate_and_normalize_vote_options(options)
            options.symbolize_keys!
            options[:votee_id] = Helpers.try_to_convert_string_to_object_id(options[:votee_id])
            options[:voter_id] = Helpers.try_to_convert_string_to_object_id(options[:voter_id])
            options[:value] &&= options[:value].to_sym
          end
        
          def new_vote_query_and_update(options)
            
            if options[:value] == :up
              positive_voter_ids = :votes_up
              positive_votes_count = :up_count
            else
              positive_voter_ids = :votes_down
              positive_votes_count = :down_count
            end

            # Validate voter_id did not vote for votee_id yet
            return {
              :id => options[:votee].id,   
              'votes.up' => { '$ne' => options[:voter_id] }, 
              'votes.down' => { '$ne' => options[:voter_id] }
            },{
              :push => { positive_voter_ids =>  options[:voter_id] },
              :count => 1,
              positive_votes_count => 1,
              :point => options[:voteable][options[:value]]
            }
          end

          
          def revote_query_and_update(options)
            
            if options[:value] == :up
              positive_voter_ids = :votes_up
              negative_voter_ids = :votes_down
              negative_voter_tag = 'votes.down'
              positive_voter_tag = 'votes.up'
              positive_votes_count = :up_count
              negative_votes_count = :down_count
              point_delta = options[:voteable][:up] - options[:voteable][:down]
            else
              positive_voter_ids = :votes_down
              negative_voter_ids = :votes_up
              negative_voter_tag = 'votes.up'
              positive_voter_tag = 'votes.down'
              positive_votes_count = :down_count
              negative_votes_count = :up_count
              point_delta = -options[:voteable][:up] + options[:voteable][:down]
            end

            # Validate if voter_id did a vote with value for votee_id
            return {
              :id => options[:votee].id,
              negative_voter_tag => options[:voter_id],
              positive_voter_tag => { '$ne' => options[:voter_id] }
            }, {
            # then update
              :pull => { negative_voter_ids => options[:voter_id] },
              :push => { positive_voter_ids => options[:voter_id] },
              positive_votes_count => 1,
              negative_votes_count => -1,
              :point => point_delta
            }
          end
          
          
          def unvote_query_and_update(options)            
  
            if options[:value] == :up
              
              positive_voter_ids = :votes_up
              #negative_voter_ids = :votes_down
              positive_voter_tag = 'votes.up'
              negative_voter_tag = 'votes.down' 
              positive_votes_count = :up_count
              
            elsif options[:value] == :down
              
              positive_voter_ids = :votes_down
              #negative_voter_ids = :votes_up
              positive_voter_tag = 'votes.down'
              negative_voter_tag = 'votes.up'
              positive_votes_count = :down_count
            
            else
              
              return nil, nil
            
            end

            # Validate if voter_id did a vote with value for votee_id
            
            return {
              :id => options[:votee].id ,
              negative_voter_tag => { '$ne' => options[:voter_id] }, 
              positive_voter_tag => options[:voter_id]
            }, {
              # then update
              :pull => { positive_voter_ids => options[:voter_id] },
              positive_votes_count => -1,
              :count => -1,
              :point => - options[:voteable][options[:value]]
            }
            
          end
          

          def update_parent_votes(doc, options)
            
            raise "parent voting unsupported for embedded documents (yet!)"
            # VOTEABLE[name].each do |class_name, voteable|
            #   if metadata = voteable_relation(class_name)
            #     if (parent_id = doc[voteable_foreign_key(metadata)]).present?
            #       parent_ids = parent_id.is_a?(Array) ? parent_id : [ parent_id ]
            #       class_name.constantize.collection.update( 
            #         { '_id' => { '$in' => parent_ids } },
            #         { '$inc' => parent_inc_options(voteable, options) },
            #         { :multi => true }
            #       )
            #     end
            #   end
            # end
          end

          
          # def parent_inc_options(voteable, options)
          #   inc_options = {}
          # 
          #   if options[:revote]
          #     if options[:value] == :up
          #       inc_options['votes.point'] = voteable[:up] - voteable[:down]
          #       unless voteable[:update_counters] == false
          #         inc_options['votes.up_count'] = +1
          #         inc_options['votes.down_count'] = -1
          #       end
          #     else
          #       inc_options['votes.point'] = -voteable[:up] + voteable[:down]
          #       unless voteable[:update_counters] == false
          #         inc_options['votes.up_count'] = -1
          #         inc_options['votes.down_count'] = +1
          #       end
          #     end
          # 
          #   elsif options[:unvote]
          #     inc_options['votes.point'] = -voteable[options[:value]]
          #     unless voteable[:update_counters] == false
          #       inc_options['votes.count'] = -1
          #       if options[:value] == :up
          #         inc_options['votes.up_count'] = -1
          #       else
          #         inc_options['votes.down_count'] = -1
          #       end
          #     end
          # 
          #   else # new vote
          #     inc_options['votes.point'] = voteable[options[:value]]
          #     unless voteable[:update_counters] == false
          #       inc_options['votes.count'] = +1
          #       if options[:value] == :up
          #         inc_options['votes.up_count'] = +1
          #       else
          #         inc_options['votes.down_count'] = +1
          #       end
          #     end
          #   end
          # 
          #   inc_options
          # end     
          
          
        end
        
      end
    end
  
end
