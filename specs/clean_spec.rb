require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe JCore::Clean do
  
  describe '.pre_process' do
    
    it 'should convert html entities to normalized utf8 form' do
      word = '&eacute;lan&nbsp;hawk'
      JCore::Clean.pre_process(word).should == [101, 769, 108, 97, 110, 32, 104, 97, 119, 107].pack('U*')
    end
    
    it 'should strip tags if :strip_tags => true' do
      word = '<div><a href="ram.html">ram</a></div>'
      JCore::Clean.pre_process(word, :strip_tags => true).should == "ram"
      JCore::Clean.pre_process(word).should_not == "ram"
    end
    
    it 'should convert to ascii if :ascii => true' do
      word = '&eacute;lan&nbsp;hawk'
      JCore::Clean.pre_process(word, :ascii => true).should == "elan hawk"
      JCore::Clean.pre_process(word).should_not == "elan hawk"
    end
    
    it 'should remove punctuation marks if :punctuation => false' do
      word = 'elan-hawk'
      JCore::Clean.pre_process(word, :punctuation => false).should == "elan hawk"
      JCore::Clean.pre_process(word).should_not == "elan hawk"
    end
    
  end
  
  describe '.author' do
    
    it 'should take language as second optional parameter' do
      lambda{ JCore::Clean.author( 'Foo' ) }.should_not raise_error
      lambda{ JCore::Clean.author( 'Foo', 'en' ) }.should_not raise_error
      lambda{ JCore::Clean.author( 'Foo', 'de' ) }.should_not raise_error 
    end
    
    it 'should reduce remove agency name' do
      author = "(Mark Spencer/dpa)"
      JCore::Clean.author(author, 'en').should == "Mark Spencer"
    end
    
    it 'should remove all the tags' do
      author = "<a><span>Mark Spencer</span></a>"
      JCore::Clean.author(author, 'en').should == "Mark Spencer"
    end
    
    it 'should return an array of names if their are more than one' do
      author = "Mark Spencer, James Bond"
      JCore::Clean.author(author, 'en').should be_include('Mark Spencer')
      JCore::Clean.author(author, 'en').should be_include('James Bond')
    end
    
    it 'should remove punctuation marks' do
      author = "Mark J. Spencer, J. L. Bird"
      JCore::Clean.author(author, 'en').should be_include('Mark J Spencer')
      JCore::Clean.author(author, 'en').should be_include('J L Bird')
    end
    
  end
  
end