require 'rubygems'
require 'hpricot'

module JCore
  
  #
  # XPath Command is one xpath command followed by directives and/or conversion method 
  #  can take directives like ::delete::, ::select::
  #  and can also take string convertion method inner_html ( default ), to_s ( calls to_s ), text ( calls inner_text ) when converting Hpricot Elements to strings
  #  e.g. 
  #    "div.ItemArtikel/h1:first/a" which tells get the desired <a> element and convert to string using inner_html
  #    "div.ItemArtikel/h1:first/a to_s" which tells to get the desired <a> element and convert to string using to_s
  #    "div.ItemArtikel/h1:first/a text" which tells to get the desired <a> element and convert to string using inner_text
  #    "div.ItemArtikel/h1:first/* ::delelte::div.ItemArtikel/h1:first/span:last to_s" which tells that to get all the items desired <h1> and remove the last <span> element if it exists and 
  #       convert using to_s the article
  #    "div.ItemArtikel/h1:first/* ::select::text? to_s" which tells that to get all the elements of desired <h1> and select only those elements which are text
  #
  
  class XPathCommand
    
    attr_reader :xpath
    attr_reader :convert
    attr_reader :selection
    attr_reader :operations
    
    def initialize(text)
      @convert = 'inner_html'
      @operations = Array.new
      tokens = text.split(' ').uniq.select{|x| !x.empty? }
      @xpath = tokens.shift
      while( token = tokens.shift)
        case( token ) when /^::delete::/ : @operations.push( [ 'delete', token.gsub('::delete::', '' ) ] )
        when /^::select::/ : @selection = token.gsub('::select::', '')
        when 'to_s' : @convert = 'to_s' 
        when 'text' : @convert = 'inner_text'
        end
      end
    end
    
    def match(doc, options={})
      data = (doc/xpath)
      # For now used only for the delete
      operations.each do | method, subpath |
        results = doc/subpath
        results.each do |result|
          data.send( method, result )
        end
      end
      result = data.select{ |x| !x.nil? } # remove items which are nil
      result = result.select{ |x| x.send(selection) } if selection # Do the selection based on some criteria text? elem? etc.
      result = result.collect{ |x| x.send( convert ) }  # Do the converstion to text using to_s/inner_html/inner_text
      result.collect!{ |x| x.match(/#{options[:match]}/m).to_s } if options[:match] # Do the matching to subselect the result
      result = result.select{ |x| !whitespace?(x) } # Remove the whitespace from the results
      result = result.first if result.size < 2 # Return the first element if result set contains less than 2 elementss
      return result
    end
    
    protected
    
    def whitespace?( text )
      text ? text.match(/\A\s*\z/) : nil
    end
    
  end
  
  
  #
  # XPath tag can contain multiple xpath commands separated by commas which becomes a chain of fallbacks.
  # Apply first command if it does not yield anything, apply the second and so on
  # e.g
  # <headline-label xpath="div.ItemArtikel/h1:first/a, div.ItemArtikel/h1:first" />
  # 
  # Options can be attributes like match <foo-label xpath="xpath-command(s)" match="\(.+\)\s+$" />
  # 
  class XPath
    
    attr_reader :xpaths
    attr_reader :options
    
    def initialize(xpath, options={})
      @xpaths = xpath.to_s.split(',').collect{ |x| JCore::XPathCommand.new(x.strip) }
      @options = options
    end
    
    def match(doc)
      xpaths.each do |xpath|
        result = xpath.match( doc, options )
        return( result ) if result && !result.empty?
      end
      return nil
    end
    
  end
  
  #
  # Document modifier uses Hpricot to find the element and to do some stuff around it
  # e.g. delete the element, insert before, insert after, replace the element
  #
  # <modify-doc at="div#mf_cont" action="insert_before"></p></modify-doc>
  #
  class Mod
    
    attr_reader :at
    attr_reader :action
    attr_reader :text
    
    def initialize( at, action, text )
      @at = at
      @action = action
      @text = text
    end
    
    def apply( doc )
      hdoc = Hpricot(doc)
      elem = hdoc.at(at)
      return nil unless elem
      text = elem.to_s
      hdoc.to_s.gsub( text, modified_text( text ) )
    end
    
    protected
    
    def modified_text( text )
      case action when 'insert_before' : "#{@text}#{text}" 
      when 'insert_after' : "#{text}#{@text}"
      when 'replace' :  @text.to_s
      when 'delete' : '' end
    end
    
  end
  
end