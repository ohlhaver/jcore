require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe JCore::Token do
  
  describe ':text' do
    
    before do
      @token = JCore::Token.new(:text, "foo text")
    end
    
    it 'should not be token' do
      @token.should_not be_is_token
    end
    
    it 'should not be label' do
      @token.should_not be_is_label
    end
    
    it 'should not be start tag' do
      @token.should_not be_start_tag
    end
    
    it 'should not be end tag' do
      @token.should_not be_end_tag
    end
    
  end
  
  describe 'with opening non-label tag containing attributes' do
    
    before do
      @token = JCore::Token.new("<div id='32' class='foo'>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should_not be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<div>"
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
  end
  
  describe 'with opening non-label tag without attributes' do
    
    before do
      @token = JCore::Token.new("<div>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should_not be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<div>"
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
  end
  
  describe 'with opening label tag without attributes' do
    
    before do
      @token = JCore::Token.new("<author-label>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should be_is_label
    end
    
    it 'should store the label correctly' do
      @token.label.should == :author
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
  end
  
  describe 'with opening label tag with attributes' do
    
    before do
      @token = JCore::Token.new("<author-label id='1'>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<author-label>"
    end
    
    it 'should store the label correctly' do
      @token.label.should == :author
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
  end
  
  describe 'with closing label tag' do
    
    before do
      @token = JCore::Token.new("</author-label>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"</author-label>"
    end
    
    it 'should store the label correctly' do
      @token.label.should == :author
    end
    
    it 'should be a start_tag' do
      @token.should_not be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should be_end_tag
    end
    
  end
  
  describe 'with closing non-label tag' do
    
    before do
      @token = JCore::Token.new("</div>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should_not be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"</div>"
    end
    
    it 'should be a start_tag' do
      @token.should_not be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should be_end_tag
    end
    
  end
  
  describe 'with auto-closing tag' do
    
    before do
      @token = JCore::Token.new("<div />")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should not be label' do
      @token.should_not be_is_label
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<div/>"
    end
    
    it 'should be a start_tag' do
      @token.should_not be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
    it 'should be autoclosing_tag' do
      @token.should be_autoclosing_tag
    end
    
  end
  
  describe 'with opening modifier tag with attributes' do
    
    before do
      @token = JCore::Token.new("<modify-doc at='1'>")
      puts @token
      puts @token.token
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should be label' do
      @token.should be_is_label
    end
    
    it 'should be modifier' do
      @token.should be_modifier
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<modify-doc>"
    end
    
    it 'should store the label correctly' do
      @token.label.should == :'modify-doc'
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
    it 'should return attr_value for at' do
      @token.attr_value('at').should == "1"
    end
    
  end
  
  describe 'with opening modifier tag with attributes' do
    
    before do
      @token = JCore::Token.new("</modify-doc>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should be label' do
      @token.should be_is_label
    end
    
    it 'should be modifier' do
      @token.should be_modifier
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"</modify-doc>"
    end
    
    it 'should store the label correctly' do
      @token.label.should == :'modify-doc'
    end
    
    it 'should not be a start_tag' do
      @token.should_not be_start_tag
    end
    
    it 'should be end_tag' do
      @token.should be_end_tag
    end
    
  end
  
  describe 'with opening modifier tag without attributes' do
    
    before do
      @token = JCore::Token.new("<modify-doc>")
    end
    
    it 'should be token' do
      @token.should be_is_token
    end
    
    it 'should be label' do
      @token.should be_is_label
    end
    
    it 'should be modifier' do
      @token.should be_modifier
    end
    
    it 'should store the condensed token' do
      @token.token.should == :"<modify-doc>"
    end
    
    it 'should store the label correctly' do
      @token.label.should == :'modify-doc'
    end
    
    it 'should be a start_tag' do
      @token.should be_start_tag
    end
    
    it 'should not be end_tag' do
      @token.should_not be_end_tag
    end
    
  end
  
end