require File.join( File.dirname(__FILE__), '../clean.rb' )
begin
# Rails2
require 'activerecord'
$scope_method = 'named_scope'
rescue LoadError
# Rails3
require 'active_record'
$scope_method = 'scope'
end
require 'digest/md5'
# set $
#$jcore_db_config = YAML.load_file( File.join( RAILS_ROOT, '/config/jcore_story.yml' ) )
#$jcore_env = RAILS_ENV

module JCore
  
  class Base < ActiveRecord::Base
    self.establish_connection( $jcore_db_config[ $jcore_env ] )
  end
  
  class Migration < ActiveRecord::Migration
    
    self.verbose = false
    
    def self.connection
      JCore::Base.connection
    end
    
  end
  
  class DB < JCore::Migration
    
    def self.up
      create_table :stories do |t|
        t.string   :title, :limit => 255
        t.string   :author_names, :limit => 2000
        t.string   :url, :limit => 2000
        t.string   :source_name, :limit => 255
        t.string   :feed_url, :limit => 2000
        t.string   :language_code, :limit => 5
        t.string   :image_url, :limit => 2000
        t.integer  :image_height
        t.integer  :image_width
        t.string   :image_type, :limit => 20
        t.boolean  :unread, :default => true, :null => :false
        t.string   :title_checksum, :limit => 255
        t.string   :url_checksum, :limit => 40
        t.datetime :created_at
        t.index    :title_checksum, :name => 'story_titles_idx'
        t.index    [ :source_name, :url_checksum ], :name => 'story_urls_idx'
        t.index    :unread, :name => 'unread_stories_idx'
      end
      create_table :blacklisted_authors do |t|
        t.string :keyword
        t.index :keyword, :unique => true
      end
    end
    
    def self.down
      drop_table :stories
      drop_table :blacklisted_authors
    end
    
  end

  class DB_002 < JCore::Migration
    def self.up
      add_column :stories, :video, :boolean, :default => false, :null => false
      add_column :stories, :opinion, :boolean, :default => false, :null => false
      add_column :stories, :content, :text, :limit => 50_000
      add_column :stories, :categories, :string, :limit => 2_000
    end

    def self.down
      remove_column :stories, :video
      remove_column :stories, :opinion
      remove_column :stories, :content
      remove_column :stories, :categories
    end
  end
  
  class BlacklistedAuthor < JCore::Base
    self.set_table_name :blacklisted_authors
    
    validates_uniqueness_of :keyword
    
    def self.includes?( author_name )
      !find( :first, :conditions => [ '? REGEXP keyword', author_name ] ).nil?
    end
  end
  
  class Story < JCore::Base
    
    self.set_table_name :stories

    serialize :author_names, Array
    serialize :categories, Array

    before_create :duplicate_title_check, :duplicate_url_check, :clean_author_name, :clean_categories
    
    self.send( $scope_method, :unread, { :conditions => { :unread => true } } )
    
    cattr_accessor :poll_frequency

    self.poll_frequency = 60
    
    validates_presence_of :title, :source_name, :url, :feed_url, :language_code, :created_at
    has_one :story_content, :dependent => :delete
    
    def mark_read
      update_attribute( :unread, false )
    end
    
    #
    # mode poll waits for new story if there are none
    # mode nopoll iterates over all new story and
    # default mode is :poll
    #
    def self.each_new_story( mode = :poll, limit = 1000, &block )
      limit = ( mode == :test ? ( limit > 10 ? 10 : limit ) : limit )
      loop do
        stories = unread.all( :limit => limit ) rescue []
        if stories.size.zero?
          break unless mode == :poll
          sleep( self.poll_frequency )
        else
          stories.each( &block )
          break if mode == :test
          self.mark_read( stories.collect!( &:id ) )
        end
      end
    end
    
    def self.mark_read( story_ids )
      update_all( [ 'unread=?', false ], { :id => story_ids } )
    end
    
    def image
      return nil if image_url.blank?
      { :url => image_url, :height => image_height, :width => image_width, :content_type => image_type }
    end
    
    def image=( image_hash )
      image_hash.stringify_keys! # stringify keys
      self.image_url = image_hash['download_url']
      self.image_height = image_hash['height']
      self.image_width = image_hash['width']
      self.image_type = image_hash['content_type']
    end
    
    protected
    
    def duplicate_title_check
      self.title_checksum = self.title.mb_chars.downcase.gsub(/\s+/,'_').gsub(/\W+/,'').to_s
      errors.add( 'title', :already_exists ) if JCore::Story.exists?( { :title_checksum => self.title_checksum } )
      return errors.blank?
    end
    
    def duplicate_url_check
      self.url_checksum = Digest::MD5.hexdigest( self.url )
      errors.add( 'url', :already_exists ) if JCore::Story.exists?( { 
        :source_name => self.source_name, :url_checksum => self.url_checksum 
      } )
      return errors.blank?
    end
    
    def clean_author_name
      self.author_names = Array( self.author_names )
      self.author_names = self.author_names.inject( [] ) do |authors, name|
        a_ns = Array( JCore::Clean.author( name ) )
        a_ns.each do |a_n|
           authors.push( a_n.mb_chars[0, 100] ) # author names are truncated at 100 chars
        end
        authors
      end
      # black listed authors are removed
      self.author_names.delete_if { |author|
        JCore::BlacklistedAuthor.includes?( author )
      }
      errors.add( 'author_names', :blank ) if self.author_names.blank? && self.language_code != 'de'
      return errors.blank?
    end

    def clean_categories
      self.categories = Array( self.categories )
    end
    
  end

end
