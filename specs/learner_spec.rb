require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe JCore::Learner do
  
  describe 'with zero fields to extract' do
     before do
       @document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
       @template = JCore::Template.new([], :ft, 3)
     end

     it 'should return blank template' do
       @template = JCore::Learner.learn(@document, @template)
       @template.should be_empty
     end

  end
  
  describe 'with one field to extract' do
    before do
      @document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
      @template = JCore::Template.new([:author], :ft, 3)
    end
  
    it 'should learn the prefix pattern correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].prefix.should  be_include( [:'<h2>', :'</h2>', :'<p>'] )
    end
  
    it 'should learn the suffix pattern correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].suffix.should be_include( [:'</p>', :'<p>', :'</p>'] )
    end
  end
  
  describe 'with two fields to extract' do
    before do
      @document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
      @template = JCore::Template.new([:author, :summary], :ft, 3)
    end
  
    it 'should learn the prefix pattern for author correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].prefix.should  be_include( [:'<h2>', :'</h2>', :'<p>'] )
    end
  
    it 'should learn the suffix pattern for author correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].suffix.should be_include( [:'</p>', :'<p>', :'</p>'] )
    end
    
    it 'should learn the prefix pattern for summary correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:summary].prefix.should  be_include( [:'<div>', :'<div>', :'<p>'] )
    end
  
    it 'should learn the suffix pattern for summary correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:summary].suffix.should be_include( [:'</p>', :'<div>', :'<div>'] )
    end
    
  end
  
  describe 'with a field having multiple labels to extract' do
    before do
      @document = File.open(File.dirname(__FILE__) + '/data/labeled/story_001.html').read
      @template = JCore::Template.new([:author, :summary, :text], :ft, 3)
    end
  
    it 'should learn the prefix pattern for author correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].prefix.should  be_include( [:'<h2>', :'</h2>', :'<p>'] )
    end
  
    it 'should learn the suffix pattern for author correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:author].suffix.should be_include( [:'</p>', :'<p>', :'</p>'] )
    end
    
    it 'should learn the prefix pattern for summary correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:summary].prefix.should  be_include( [:'<div>', :'<div>', :'<p>'] )
    end
  
    it 'should learn the suffix pattern for summary correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:summary].suffix.should be_include( [:'</p>', :'<div>', :'<div>'] )
    end
    
    it 'should learn the first prefix pattern for text correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:text].prefix.should  be_include( [:'</div>', :'</div>', :'<p>'] )
    end
    
    it 'should learn the second prefix pattern for text correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:text].prefix.should  be_include( [:'</blockquote>', :'<p/>', :'<p>'] )
    end
  
    it 'should learn the first suffix pattern for text correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:text].suffix.should be_include( [:'</p>', :'<blockquote>', :'<div>'] )
    end
    
    it 'should learn the second suffix pattern for text correctly' do
      @template = JCore::Learner.learn(@document, @template)
      @template[:text].suffix.should be_include( [:'</p>', :'</div>', :'</div>'] )
    end
    
  end
  
end