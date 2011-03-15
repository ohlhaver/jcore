require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

$jcore_db_config = { 'test' => { 
  :adapter => 'mysql',
  :database => 'jcore_test',
  :username => 'root',
  :password => '',
  :pool => 5
} }
$jcore_env = 'test'

require File.dirname(__FILE__) + '/../lib/jcore/db.rb'

describe JCore::Story do
  
  before(:all) do
    JCore::DB_002.down rescue
    JCore::DB.down rescue
    JCore::DB.up
    JCore::DB_002.up
  end
  
  before(:each) do
    @valid_story_without_author = {
      :title => 'Foo',
      :url => 'http://foo.com',
      :feed_url => 'http://foofeed.com',
      :source_name => 'foosource.com',
      :created_at => Time.now.utc.to_s(:db),
      :language_code => 'en',
    }
    @valid_story = @valid_story_without_author.merge(
      :author_names => [ 'Foo' ]
    )
    @valid_story_with_junk_author = @valid_story_without_author.merge(
      :author_names => [ 'Blah Blah' ]
    )    
    @duplicate_title_attrs = @valid_story.merge(
      :url => 'http://foodo.com',
      :created_at => 1.day.ago.utc.to_s(:db),
      :language_code => 'en',
      :author_names => [ 'Doo' ]
    )
    @duplicate_url_attrs = @valid_story.merge(
      :title  => 'Voo',
      :created_at => 2.days.ago.utc.to_s(:db),
      :language_code => 'en',
      :author_names => [ 'Voo' ]
    )
  end
  
  after(:each) do
    JCore::Story.delete_all
  end

  it "should validate presence of title, url, source_name, feed_url, language_code and created_at" do
    story = JCore::Story.new
    story.save
    [ :title, :url, :source_name, :feed_url, :language_code, :created_at ].each do |attribute|
      story.errors.on(attribute).should_not be_nil
    end
  end
  
  it "should store valid story" do
    story = JCore::Story.create( @valid_story )
    story.should_not be_new_record
    story.author_names.should be_include( 'Foo' )
    story.categories.should == []
  end
  
  it "should not store stories without author" do
    story = JCore::Story.new( @valid_story_without_author )
    story.save.should be_false
    story.errors.on(:author_names).should_not be_nil
  end
  
  it "should store stories without author only for german language" do
    story = JCore::Story.new( @valid_story_without_author )
    story.language_code = 'de'
    story.save.should be_true
  end

  it "should not store stories with duplicate title" do
    story = JCore::Story.create( @valid_story )
    story.should_not be_new_record
    story = JCore::Story.create( @duplicate_title_attrs )
    story.save.should be_false
    story.errors.on(:title)
  end
  
  it "should not store stories with duplicate url" do
    story = JCore::Story.create( @valid_story )
    story.should_not be_new_record
    story = JCore::Story.create( @duplicate_url_attrs )
    story.save.should be_false
    story.errors.on(:title)
  end
  
  it "should remove authors which matches the blacklist experession" do
    JCore::BlacklistedAuthor.create( :keyword => 'Blah' )
    story = JCore::Story.new( @valid_story_with_junk_author )
    story.save.should be_false
    story.errors.on(:author_names).should_not be_nil
  end
  
  it "should provide \"each_new_story\" method to iterate over all unread stories" do
    JCore::Story.transaction do
      20.times do |t|
        JCore::Story.create( @valid_story.merge( :title => "Title #{t}", :url => "Url #{t}" ) )
      end
    end
    JCore::Story.unread.count.should == 20
    JCore::Story.each_new_story( :no_poll, 10 ){ |s| next }
    JCore::Story.unread.count.should == 0
  end
  
  after(:all) do
    JCore::DB.down
  end
  
end
