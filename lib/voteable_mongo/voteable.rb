require 'voteable_mongo/voting'
require 'voteable_mongo/embedded_voting'
require 'voteable_mongo/integrations/mongoid'
require 'voteable_mongo/integrations/mongo_mapper'
require 'voteable_mongo/extensions/scopes'
require 'voteable_mongo/extensions/embedded_scopes'

module Mongo
  module Voteable
    extend ActiveSupport::Concern

    DEFAULT_VOTES = {
      'up' => [],
      'down' => [],
      'up_count' => 0,
      'down_count' => 0,
      'count' => 0,
      'point' => 0
    }

    included do

      if defined?(Mongoid) && defined?(field)
        include Mongo::Voteable::Voting
        include Mongo::Voteable::Integrations::Mongoid
      elsif defined?(MongoMapper)
        include Mongo::Voteable::Voting
        include Mongo::Voteable::Integrations::MongoMapper
      end
      
    end

    # How many points should be assigned for each up or down vote and other options
    # This hash should manipulated using voteable method
    VOTEABLE = {}

    module ClassMethods
      # Set vote point for each up (down) vote on an object of this class
      # 
      # @param [Hash] options a hash containings:
      # 
      # voteable self, :up => +1, :down => -3
      # voteable Post, :up => +2, :down => -1, :update_counters => false # skip counter update
      def voteable(klass = self, options = nil)
        VOTEABLE[name] ||= {}
        VOTEABLE[name][klass.name] ||= options
        
        if self.embedded?
          include Mongo::Voteable::EmbeddedVoting
          include Mongo::Voteable::Extensions::EmbeddedScopes
        else
          include Mongo::Voteable::Extensions::Scopes
        end
        
        if klass == self
          if options[:index] == true
            create_voteable_indexes
          end
        else
          VOTEABLE[name][name][:update_parents] ||= true
        end
      end
      
      # Check if voter_id do a vote on votee_id
      #
      # @param [Hash] options a hash containings:
      #   - :votee_id: the votee document id
      #   - :voter_id: the voter document id
      # 
      # @return [true, false]
      def voted?(options) #historic
        validate_and_normalize_vote_options(options)
        subcollection_prefix = self.voteable_embedded_collection_name
        voted_by(options[:voter_id]).where( subcollection_prefix.to_sym.elem_match => { :id => options[:votee_id] }).exists?

      end
       
      # Check if voter_id do an up vote on votee_id
      #
      # @param [Hash] options a hash containings:
      #   - :votee_id: the votee document id
      #   - :voter_id: the voter document id
      # 
      # @return [true, false]
      def up_voted?(options) #historic
        validate_and_normalize_vote_options(options)        
        subcollection_prefix = self.voteable_embedded_collection_name
        up_voted_by(options[:voter_id]).where(subcollection_prefix.to_sym.elem_match => { :id => options[:votee_id] }).exists?
      end
      
      # Check if voter_id do a down vote on votee_id
      #
      # @param [Hash] options a hash containings:
      #   - :votee_id: the votee document id
      #   - :voter_id: the voter document id
      # 
      # @return [true, false]
      def down_voted?(options) #historic
        validate_and_normalize_vote_options(options)
        subcollection_prefix = self.voteable_embedded_collection_name
        down_voted_by(options[:voter_id]).where(subcollection_prefix.to_sym.elem_match => { :id => options[:votee_id] }).exists?
      end

      def create_voteable_indexes
        # Compound index _id and voters.up, _id and voters.down
        # to make up_voted_by, down_voted_by, voted_by scopes and voting faster
        # Should run in background since it introduce new index value and
        # while waiting to build, the system can use _id for voting
        # http://www.mongodb.org/display/DOCS/Indexing+as+a+Background+Operation

        voteable_index [{ 'votes.up' => 1, '_id' => 1 }, {:unique => true}]
        voteable_index [{'votes.down' => 1, '_id' => 1 }, {:unique => true}]

        # Index counters and point for desc ordering
        voteable_index [{'votes.up_count' => -1}]
        voteable_index [{'votes.down_count' => -1}]
        voteable_index [{'votes.count' => -1}]
        voteable_index [{'votes.point' => -1 }]
      end
    end
    
    # Make a vote on this votee
    #
    # @param [Hash] options a hash containings:
    #   - :voter_id: the voter document id
    #   - :value: vote :up or vote :down
    #   - :revote: change from vote up to vote down
    #   - :unvote: unvote the vote value (:up or :down)
    def vote(options, value = nil)
        
      opt_new = {}
      unless options.is_a?(Hash)

        if ! options.is_a?(Mongo::Voter)
          opt_new[:voter] = nil
          if options.is_a?(BSON::ObjectId)
            opt_new[:voter_id] = options
          elsif options.is_a?(String)
            opt_new[:voter_id] = Helpers.try_to_convert_string_to_object_id(options)
          else
            raise '"'+ options.class.to_s + '" is not a voter.'
          end
        else
          opt_new[:voter_id] = options.id
          opt_new[:voter] = options
        end
        
        opt_new[:unvote] = value.nil? ? true : false
        opt_new[:revote] = value.nil? ? false : vote_value(opt_new[:voter_id]).present?
        opt_new[:value] = value.nil? ? vote_value(opt_new[:voter_id]) : value
      
      else
      
        opt_new[:voter_id] = options[:voter_id].nil? ? options[:voter].id : options[:voter_id]
            
        opt_new[:value] = options[:unvote].nil? ? value.nil? ? options[:value] : value : options[:value]
        if options[:unvote]
          opt_new[:value] = options[:value].nil? ? vote_value(options[:voter_id]) : options[:value]
          opt_new [:unvote] = true
        else
          opt_new[:revote] = options[:revote].nil? ? vote_value(options[:voter_id]).present? : options[:revote]
        end

        
      end
      opt_new[:votee_id] = self.id
      opt_new[:votee] = self
      
      self.class.vote(opt_new)
    end

    # Get a voted value on this votee
    #
    # @param voter is object or the id of the voter who made the vote
    def vote_value(voter)
      
      voter_id = voter.is_a?(String) ? Helpers.try_to_convert_string_to_object_id(voter) : voter_id = Helpers.get_mongo_id(voter) #.to_s
       
      return :up if up_voter_ids.include?(voter_id)
      return :down if down_voter_ids.include?(voter_id)
    end

    def voted_by?(voter)
      !!vote_value(voter)
    end

    # Array of up voter ids
    def up_voter_ids
      votes[:up].nil? ? [] : votes[:up]
    end

    # Array of down voter ids
    def down_voter_ids
      votes[:down].nil? ? [] : votes[:down]
    end

    # Array of voter ids
    def voter_ids
      up_voter_ids + down_voter_ids
    end

    # Get the number of up votes
    def up_votes_count
      votes.try(:[], 'up_count') || 0
    end

    # Get the number of down votes
    def down_votes_count
      votes.try(:[], 'down_count') || 0
    end

    # Get the number of votes
    def votes_count
      votes.try(:[], 'count') || 0
    end

    # Get the votes point
    def votes_point
      votes.try(:[], 'point') || 0
    end

    # Get up voters
    def up_voters(klass)
      klass.where(:_id => { '$in' =>  up_voter_ids })
    end

    # Get down voters
    def down_voters(klass)
      klass.where(:_id => { '$in' => down_voter_ids })
    end

    # Get voters
    def voters(klass)
      klass.where(:_id => { '$in' => voter_ids })
    end
  end
end
