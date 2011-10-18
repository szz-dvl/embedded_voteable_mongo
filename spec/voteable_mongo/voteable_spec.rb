require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Mongo::Voteable do
  
  context 'when :index is passed as an argument' do
    before do
      Post.collection.drop_indexes
      Category.collection.drop_indexes
      
      Post.create_voteable_indexes
      Category.create_voteable_indexes
    end
  
    it 'defines indexes' do
      [Post, Category].each do |klass|
        [ 'votes.up_1__id_1',
          'votes.down_1__id_1'
        ].each { |index_key|
          klass.collection.index_information.should have_key index_key
          klass.collection.index_information[index_key]['unique'].should be_true
        }
  
        [ 'votes.count_-1',
          'votes.up_count_-1',
          'votes.down_count_-1',
          'votes.point_-1'
        ].each { |index_key|
          klass.collection.index_information.should have_key index_key
        }
      end
    end
  end
  
  before :all do
    @category1 = Category.create!(:name => 'xyz')
    @category2 = Category.create!(:name => 'abc')
    
    @post1 = Post.create!(:title => 'post1')
    @post2 = Post.create!(:title => 'post2')

    @post1.category_ids = [@category1.id, @category2.id]
    @post1.save!

    @comment = @post2.comments.create!
    
    @user1 = User.create!
    @user2 = User.create!
    
    if Class.const_defined?("Mongoid")

      @question1 = Question.create!(:question => 'How warm is the sun on Sunday?')
      @question2 = Question.create!(:question => 'How wet is the rain on Friday?')

      answer1 = @question1.answers.create!(:position=>1, :answer=>"It's very warm. Like a bazillion degrees.")
      answer2 = @question1.answers.create!(:position=>2, :answer=>"Pfff. It's a cool star, astrophysically speaking. I'll show you a hot star. Look at this: http://en.wikipedia.org/wiki/R136a1")
      answer3 = @question2.answers.create!(:position=>1, :answer=>"Very, very wet.")
      answer4 = @question2.answers.create!(:position=>2, :answer=>"Less wet than it is on Saturday.")
      
    end
    
    
  end
  
  it "vote for unexisting post" do
    @user1.vote(:votee_class => Post, :votee_id => BSON::ObjectId.new, :value => :up).should == false
    if Class.const_defined?("Mongoid")
      @user2.vote(:votee_class => Answer, :votee_id => BSON::ObjectId.new, :value => :down, :parent_doc_id => @question1.id).should == false
    end
  end
  
  context "just created" do
    it 'votes_count, up_votes_count, down_votes_count, votes_point should be zero' do
      @category1.up_votes_count.should == 0
      @category1.down_votes_count.should == 0
      @category1.votes_count.should == 0
      @category1.votes_point.should == 0

      @category2.up_votes_count.should == 0
      @category2.down_votes_count.should == 0
      @category2.votes_count.should == 0
      @category2.votes_point.should == 0

      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 0
      @post1.votes_count.should == 0
      @post1.votes_point.should == 0

      @post2.up_votes_count.should == 0
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 0
      @post2.votes_point.should == 0

      @comment.up_votes_count.should == 0
      @comment.down_votes_count.should == 0
      @comment.votes_count.should == 0
      @comment.votes_point.should == 0
    end
    
    it 'up_voter_ids, down_voter_ids should be empty' do
      @category1.up_voter_ids.should be_empty
      @category1.down_voter_ids.should be_empty

      @category2.up_voter_ids.should be_empty
      @category2.down_voter_ids.should be_empty

      @post1.up_voter_ids.should be_empty
      @post1.down_voter_ids.should be_empty

      @post2.up_voter_ids.should be_empty
      @post2.down_voter_ids.should be_empty

      @comment.up_voter_ids.should be_empty
      @comment.down_voter_ids.should be_empty
    end
    
    it 'voted by voter should be empty' do
      Category.voted_by(@user1).should be_empty
      Category.voted_by(@user2).should be_empty

      Post.voted_by(@user1).should be_empty
      Post.voted_by(@user2).should be_empty
      
      Comment.voted_by(@user1).should be_empty
      Comment.voted_by(@user2).should be_empty
    end
        
    it 'revote post1 has no effect' do
      @post1.vote(:revote => true, :voter => @user1, :value => 'up')

      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 0
      @post1.votes_count.should == 0
      @post1.votes_point.should == 0
    end
    
    it 'revote post2 has no effect' do
      Post.vote(:revote => true, :votee_id => @post2.id, :voter_id => @user2.id, :value => :down)
      @post2.reload
      
      @post2.up_votes_count.should == 0
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 0
      @post2.votes_point.should == 0
    end
  end
  
  context 'user1 vote up post1 the first time' do
    before :all do
      @post = @post1.vote(:voter_id => @user1.id, :value => :up)
    end
    
    it 'validates return post' do
      @post.should be_is_a Post
      @post.should_not be_new_record

      @post.votes.should == {
        'up' => [@user1.id],
        'down' => [],
        'up_count' => 1,
        'down_count' => 0,
        'count' => 1,
        'point' => 1
      }
    end
    
    it 'validates' do
      @post1.up_votes_count.should == 1
      @post1.down_votes_count.should == 0
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1

      @post1.vote_value(@user1).should == :up
      @post1.should be_voted_by(@user1)
      @post1.vote_value(@user2.id).should be_nil
      @post1.should_not be_voted_by(@user2.id)

      @post1.up_voters(User).to_a.should == [ @user1 ]
      @post1.voters(User).to_a.should == [ @user1 ]
      @post1.down_voters(User).should be_empty

      Post.voted_by(@user1).to_a.should == [ @post1 ]
      Post.voted_by(@user2).to_a.should be_empty
      
      @category1.reload
      @category1.up_votes_count.should == 0
      @category1.down_votes_count.should == 0
      @category1.votes_count.should == 0
      @category1.votes_point.should == 3

      @category2.reload
      @category2.up_votes_count.should == 0
      @category2.down_votes_count.should == 0
      @category2.votes_count.should == 0
      @category2.votes_point.should == 3
    end
    
    it 'user1 vote post1 has no effect' do
      Post.vote(:revote => false, :votee_id => @post1.id, :voter_id => @user1.id, :value => :up)
      @post1.reload
      
      @post1.up_votes_count.should == 1
      @post1.down_votes_count.should == 0
      @post1.votes_count.should == 1
      @post1.votes_point.should == 1
      
      @post1.vote_value(@user1.id).should == :up
    end
  end
  
  context 'user2 vote down post1 the first time' do
    before :all do
      Post.vote(:votee_id => @post1.id, :voter_id => @user2.id, :value => :down)
      @post1.reload
    end
    
    it 'post1 up_votes_count is the same' do
      @post1.up_votes_count.should == 1
    end
    
    it 'post1 vote_value on user1 is the same' do
      @post1.vote_value(@user1.id).should == :up
    end
    
    it 'down_votes_count, votes_count, and votes_point changed' do
      @post1.down_votes_count.should == 1
      @post1.votes_count.should == 2
      @post1.votes_point.should == 0
      @post1.vote_value(@user2.id).should == :down
    end
    
    it 'post1 get voters' do
      @post1.up_voters(User).to_a.should == [ @user1 ]
      @post1.down_voters(User).to_a.should == [ @user2 ]
      @post1.voters(User).to_a.should == [ @user1, @user2 ]
    end
    
    it 'posts voted_by user1, user2 is post1 only' do
      Post.voted_by(@user1).to_a.should == [ @post1 ]
      Post.voted_by(@user2).to_a.should == [ @post1 ]
    end
    
    it 'categories votes' do
      @category1.reload
      @category1.up_votes_count.should == 0
      @category1.down_votes_count.should == 0
      @category1.votes_count.should == 0
      @category1.votes_point.should == -2

      @category2.reload
      @category2.up_votes_count.should == 0
      @category2.down_votes_count.should == 0
      @category2.votes_count.should == 0
      @category2.votes_point.should == -2
    end
  end
  
  context 'user1 change vote on post1 from up to down' do
    before :all do
      Post.vote(:revote => true, :votee_id => @post1.id, :voter_id => @user1.id, :value => :down)
      Mongo::Voteable::Tasks.remake_stats
      @post1.reload
    end
    
    it 'validates' do
      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 2
      @post1.votes_count.should == 2
      @post1.votes_point.should == -2

      @post1.vote_value(@user1.id).should == :down
      @post1.vote_value(@user2.id).should == :down

      Post.voted_by(@user1).to_a.should == [ @post1 ]
      Post.voted_by(@user2).to_a.should == [ @post1 ]
    end
  end
  
  context 'user1 vote down post2 the first time' do
    before :all do
      @post2.vote(:voter_id => @user1.id, :value => :down)
    end
    
    it 'validates' do
      @post2.up_votes_count.should == 0
      @post2.down_votes_count.should == 1
      @post2.votes_count.should == 1
      @post2.votes_point.should == -1
      
      @post2.vote_value(@user1.id).should == :down
      @post2.vote_value(@user2.id).should be_nil

      Post.voted_by(@user1).to_a.should == [ @post1, @post2 ]
    end
  end
  
  context 'user1 change vote on post2 from down to up' do
    before :all do
      Post.vote(:revote => true, :votee_id => @post2.id.to_s, :voter_id => @user1.id.to_s, :value => :up)
      Mongo::Voteable::Tasks.remake_stats
      @post2.reload
    end
    
    it 'validates' do
      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
      
      @post2.vote_value(@user1.id).should == :up
      @post2.vote_value(@user2.id).should be_nil

      Post.voted_by(@user1).size.should == 2
      Post.voted_by(@user1).should be_include @post1
      Post.voted_by(@user1).should be_include @post2
    end
  end
  

  context 'user1 vote up post2 comment the first time' do
    before :all do
      @comment.vote(:voter_id => @user1.id, :value => :up)
      @comment.reload
      @post2.reload
    end
    
    it 'validates' do
      @post2.up_votes_count.should == 2
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 2
      @post2.votes_point.should == 3
      
      @comment.up_votes_count.should == 1
      @comment.down_votes_count.should == 0
      @comment.votes_count.should == 1
      @comment.votes_point.should == 1
    end
  end
  
  
  context 'user1 revote post2 comment from up to down' do
    before :all do
      @user1.vote(:votee => @comment, :value => :down)
      @comment.reload
      @post2.reload
    end
    
    it 'validates' do
      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 1
      @post2.votes_count.should == 2
      @post2.votes_point.should == 0
      
      @comment.up_votes_count.should == 0
      @comment.down_votes_count.should == 1
      @comment.votes_count.should == 1
      @comment.votes_point.should == -3
    end
    
    it 'revote with wrong value has no effect' do
      @user1.vote(:votee => @comment, :value => :down)
      
      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 1
      @post2.votes_count.should == 2
      @post2.votes_point.should == 0
      
      @comment.up_votes_count.should == 0
      @comment.down_votes_count.should == 1
      @comment.votes_count.should == 1
      @comment.votes_point.should == -3
    end
  end
  
  context "user1 unvote on post1" do
    before(:all) do
      @post1.vote(:voter_id => @user1.id, :votee_id => @post1.id, :unvote => true)
      Mongo::Voteable::Tasks.remake_stats
      @post1.reload
    end
    
    it 'validates' do
      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 1
      @post1.votes_count.should == 1
      @post1.votes_point.should == -1
      
      @post1.vote_value(@user1.id).should be_nil
      @post1.vote_value(@user2.id).should == :down
      
      Post.voted_by(@user1).to_a.should_not include(@post1)
    end
  end
  
  context "@post1 has 1 down vote and -1 point, @post2 has 1 up vote, 1 down vote and 0 point" do
    it "verify @post1 counters" do
      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 1
      @post1.votes_count.should == 1
      @post1.votes_point.should == -1
    end
    
    it "verify @post2 counters" do
      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 1
      @post2.votes_count.should == 2
      @post2.votes_point.should == 0
    end    
  end
  
  context "user1 unvote on comment" do
    before(:all) do
      @user1.unvote(@comment)
      Mongo::Voteable::Tasks.remake_stats
      @comment.reload
      @post2.reload
    end
    
    it "validates" do      
      @comment.up_votes_count.should == 0
      @comment.down_votes_count.should == 0
      @comment.votes_count.should == 0
      @comment.votes_point.should == 0

      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1      
    end
  end
  
  if Class.const_defined?("Mongoid")
 
    context "just created embedded models" do
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end
      
      it 'votes_count, up_votes_count, down_votes_count, votes_point should be zero' do
        @question1.up_votes_count.should == 0
        @question1.down_votes_count.should == 0
        @question1.votes_count.should == 0
        @question1.votes_point.should == 0

        @question2.up_votes_count.should == 0
        @question2.down_votes_count.should == 0
        @question2.votes_count.should == 0
        @question2.votes_point.should == 0


        @answer1.up_votes_count.should == 0
        @answer1.down_votes_count.should == 0
        @answer1.votes_count.should == 0
        @answer1.votes_point.should == 0

        @answer2.up_votes_count.should == 0
        @answer2.down_votes_count.should == 0
        @answer2.votes_count.should == 0
        @answer2.votes_point.should == 0

        @answer3.up_votes_count.should == 0
        @answer3.down_votes_count.should == 0
        @answer3.votes_count.should == 0
        @answer3.votes_point.should == 0

        @answer4.up_votes_count.should == 0
        @answer4.down_votes_count.should == 0
        @answer4.votes_count.should == 0
        @answer4.votes_point.should == 0

      end

      it 'up_voter_ids, down_voter_ids should be empty' do
        @question1.up_voter_ids.should be_empty
        @question1.down_voter_ids.should be_empty

        @question2.up_voter_ids.should be_empty
        @question2.down_voter_ids.should be_empty

        @answer1.up_voter_ids.should be_empty
        @answer1.down_voter_ids.should be_empty

        @answer2.up_voter_ids.should be_empty
        @answer2.down_voter_ids.should be_empty

        @answer3.up_voter_ids.should be_empty
        @answer3.down_voter_ids.should be_empty

        @answer4.up_voter_ids.should be_empty
        @answer4.down_voter_ids.should be_empty
      end

      it 'voted by voter should be empty' do
        Question.voted_by(@user1).should be_empty
        Question.voted_by(@user2).should be_empty

        Answer.voted_by(@user1).should be_empty
        Answer.voted_by(@user2).should be_empty

      end

      it 'revote answer1 has no effect' do
        @answer1.vote(:revote => true, :voter => @user1, :value => 'up')

        @answer1.up_votes_count.should == 0
        @answer1.down_votes_count.should == 0
        @answer1.votes_count.should == 0
        @answer1.votes_point.should == 0
      end

      it 'revote answer2 has no effect' do
        Answer.vote(:revote => true, :votee_id => @answer2.id, :voter_id => @user2.id, :value => :down, :parent_doc_id=>@question1.id)
        @question1.reload
        @answer2 = @question1.answers.detect { |a| a.position == 2 }

        @answer2.up_votes_count.should == 0
        @answer2.down_votes_count.should == 0
        @answer2.votes_count.should == 0
        @answer2.votes_point.should == 0
      end
    end

    context 'user1 vote up answer1 the first time' do
      before :all do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        @answer = @answer1.vote(:voter_id => @user1.id, :value => :up)
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'validates return answer' do
        @answer.should be_is_a Answer
        @answer.should_not be_new_record

        @answer.votes.should == {
          'up' => [@user1.id],
          'down' => [],
          'up_count' => 1,
          'down_count' => 0,
          'count' => 1,
          'point' => 1
        }
      end

      it 'validates' do
        @answer1.up_votes_count.should == 1
        @answer1.down_votes_count.should == 0
        @answer1.votes_count.should == 1
        @answer1.votes_point.should == 1

        @answer1.vote_value(@user1).should == :up
        @answer1.should be_voted_by(@user1)
        @answer1.vote_value(@user2.id).should be_nil
        @answer1.should_not be_voted_by(@user2.id)

        @answer1.up_voters(User).to_a.should == [ @user1 ]
        @answer1.voters(User).to_a.should == [ @user1 ]
        @answer1.down_voters(User).should be_empty

        Answer.voted_by(@user1).to_a.should == [ @question1 ]
        Answer.voted_by(@user2).to_a.should be_empty

      end

      it 'user1 vote answer1 has no effect' do
        Answer.vote(:revote => false, :votee_id => @answer1.id, :voter_id => @user1.id, :value => :up, :parent_doc_id => @question1.id)
        @question1.reload
        @answer1 = @question1.answers.detect { |a| a.position == 1 }

        @answer1.up_votes_count.should == 1
        @answer1.down_votes_count.should == 0
        @answer1.votes_count.should == 1
        @answer1.votes_point.should == 1

        @answer1.vote_value(@user1.id).should == :up
      end
    end

    context 'user2 vote down answer1 the first time' do
      before :all do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        Answer.vote(:votee_id => @answer1.id, :voter_id => @user2.id, :value => :down, :parent_doc_id => @question1.id)
        @question1.reload
        # @answer1 = @question1.answers.detect { |a| a.position == 1 }
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'answer1 up_votes_count is the same' do
        @answer1.up_votes_count.should == 1
      end

      it 'answer1 vote_value on user1 is the same' do
        @answer1.vote_value(@user1.id).should == :up
      end

      it 'down_votes_count, votes_count, and votes_point changed' do
        @answer1.down_votes_count.should == 1
        @answer1.votes_count.should == 2
        @answer1.votes_point.should == 0
        @answer1.vote_value(@user2.id).should == :down
      end

      it 'answer1 get voters' do
        @answer1.up_voters(User).to_a.should == [ @user1 ]
        @answer1.down_voters(User).to_a.should == [ @user2 ]
        @answer1.voters(User).to_a.should == [ @user1, @user2 ]
      end

      it 'answers voted_by user1, user2 is answer1 only' do
        Answer.voted_by(@user1).to_a.should == [ @question1 ]
        Answer.voted_by(@user2).to_a.should == [ @question1 ]
      end

    end

    context 'user1 change vote on answer1 from up to down' do
      before :all do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        Answer.vote(:revote => true, :votee_id => @answer1.id, :voter_id => @user1.id, :value => :down, :parent_doc_id => @question1.id)
        Mongo::Voteable::Tasks.remake_stats
        @question1.reload
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'validates' do
        @answer1.up_votes_count.should == 0
        @answer1.down_votes_count.should == 2
        @answer1.votes_count.should == 2
        @answer1.votes_point.should == -2

        @answer1.vote_value(@user1.id).should == :down
        @answer1.vote_value(@user2.id).should == :down

        Answer.voted_by(@user1).to_a.should == [ @question1 ]
        Answer.voted_by(@user2).to_a.should == [ @question1 ]
      end
    end

    context 'user1 vote down answer3 the first time' do
      before :all do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        @answer3.vote(:voter_id => @user1.id, :value => :down)
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'validates' do
        @answer3.up_votes_count.should == 0
        @answer3.down_votes_count.should == 1
        @answer3.votes_count.should == 1
        @answer3.votes_point.should == -1

        @answer3.vote_value(@user1.id).should == :down
        @answer3.vote_value(@user2.id).should be_nil

        Answer.voted_by(@user1).to_a.should == [ @question1, @question2 ]
      end
    end

    context 'user1 change vote on answer3 from down to up' do
      before :all do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        Answer.vote(:revote => true, :votee_id => @answer3.id.to_s, :voter_id => @user1.id.to_s, :value => :up, :parent_doc_id => @question2.id )
        Mongo::Voteable::Tasks.remake_stats
        @question2.reload        
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'validates' do
        @answer3.up_votes_count.should == 1
        @answer3.down_votes_count.should == 0
        @answer3.votes_count.should == 1
        @answer3.votes_point.should == 1

        @answer3.vote_value(@user1.id).should == :up
        @answer3.vote_value(@user2.id).should be_nil

        Answer.voted_by(@user1).size.should == 2
        Answer.voted_by(@user1).should be_include @question1
        Answer.voted_by(@user1).should be_include @question2
      end
    end

    context "user1 unvote on answer1" do
      before(:all) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
        @answer1.vote(:voter_id => @user1.id, :votee_id => @answer1.id, :unvote => true, :parent_doc_id => @question1.id )
        Mongo::Voteable::Tasks.remake_stats
        @question1.reload
      end
      
      before(:each) do
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end

      it 'validates' do
        @answer1.up_votes_count.should == 0
        @answer1.down_votes_count.should == 1
        @answer1.votes_count.should == 1
        @answer1.votes_point.should == -1

        @answer1.vote_value(@user1.id).should be_nil
        @answer1.vote_value(@user2.id).should == :down

        Answer.voted_by(@user1).to_a.should_not include(@answer1)
      end
    end

    context "@answer1 has 1 down vote and -1 point, @answer3 has 1 up vote, 1 down vote and 0 point" do
      before(:each) do
        @question1.reload
        @question2.reload
        @answer1 = @question1.answers[0]
        @answer2 = @question1.answers[1]
        @answer3 = @question2.answers[0]
        @answer4 = @question2.answers[1]
      end
      
      it "verify @answer1 counters" do
        @answer1.up_votes_count.should == 0
        @answer1.down_votes_count.should == 1
        @answer1.votes_count.should == 1
        @answer1.votes_point.should == -1
      end

      it "verify @answer3 counters" do
        @answer3.up_votes_count.should == 1
        @answer3.down_votes_count.should == 0
        @answer3.votes_count.should == 1
        @answer3.votes_point.should == 1
      end    
    end
  end
  
  context 'final' do
    it "test remake stats" do
      Mongo::Voteable::Tasks.remake_stats

      @post1.up_votes_count.should == 0
      @post1.down_votes_count.should == 1
      @post1.votes_count.should == 1
      @post1.votes_point.should == -1

      @post2.up_votes_count.should == 1
      @post2.down_votes_count.should == 0
      @post2.votes_count.should == 1
      @post2.votes_point.should == 1
    
      @comment.up_votes_count.should == 0
      @comment.down_votes_count.should == 0
      @comment.votes_count.should == 0
      @comment.votes_point.should == 0    
    end
  end
end
