require 'rubygems'
require 'hpricot'

module JCore
  
  #
  # XPath Command takes more than one xpath commands separated by comma
  # Each command
  #  can take directives like ::delete::, ::select::
  #  and can also take string convertion method inner_html ( default ), to_s ( calls to_s ), text ( calls inner_text ) when converting Hpricot Elements to strings
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
    
    def operation?(text)
      text.match(/op\(/)
    end
    
    protected
    
    def whitespace?( text )
      text ? text.match(/\A\s*\z/) : nil
    end
    
  end
  
  
  #
  # Options can be attributes like match <foo-label xpath="xpath-command" match="\(.+\)\s+$" />
  #
  class XPath
    
    # Chain of fallback options
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
  
  # Lower the score better is the match
  # 0 == Exact Match
  class Match
    
    attr_reader :score
    attr_accessor :index
    
    def initialize(score)
      @score = score
    end
    
    def <=>(other)
      score == other.score ? index <=> other.index : score <=> other.score
    end
    
  end
  
  #
  # Pattern for the template field are the sequence of prefix tags and suffix tags which 
  # in some way define the structure of the html template page through which data is being
  # generated. e.g.
  #
  #  if the product image is embedded in the following HTML source: 
  #   ...<table><tr><td> <img> </td><td></td>... 
  # 
  # image_pattern.prefix = [ [ :'<table>', :'<tr>', :'<td>' ] ]
  # image_pattern.suffix = [ [ :'</td>', :'<td>', :'</td>' ] ]
  #
  # assuming we storing prefix of max_length = 3
  #
  class Pattern
    
    attr_reader :suffix
    attr_reader :prefix
    
    def initialize
      @suffix = Array.new
      @prefix = Array.new
    end
    
    #
    # Suffix Match are Fuzzy ( From list of possible matches best one is choose )
    #
    def self.suffix_match(seq1, seq2, max_length=20)
      score = edit_distance(seq1, seq2)
      score <= optimal_distance(seq1, seq2, max_length) && seq1.first == seq2.first ? JCore::Match.new(score) : nil
    end
    #
    # Prefix Match are Exact
    #
    def self.prefix_match(seq1, seq2)
      seq1.any? && seq1 == seq2 ? JCore::Match.new( 0 ) : nil
    end
    #
    # For a prefix there can be multiple suffix sequence found using different templates. It creates a unified suffix map for prefix patterns
    #
    def suffix_map
      index = 0
      prefix.inject({})do |map, p| 
        map[p] ||= Array.new
        map[p].push( suffix[index] ) unless map[p].include?( suffix[index] )
        index += 1
        map
      end
    end
    
    protected
    #
    # Levhenstein Edit Distance
    # Source: http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance
    #
    def self.edit_distance(seq1, seq2)
      matrix = Array.new(seq1.size+1).collect!{ Array.new(seq2.size+1, 0) }
      seq1.size.times{ |i| matrix[i+1][0] = i+1 }
      seq2.size.times{ |j| matrix[0][j+1] = j+1 }
      seq1.size.times do |i|
        seq2.size.times do |j|
          matrix[i+1][j+1] = [ matrix[i][j+1]+1, matrix[i+1][j]+1, matrix[i][j] + (seq1[i] == seq2[j] ? 0 : 1) ].min
        end
      end
      matrix[seq1.size][seq2.size]
    end
    #
    # Something that may be tweaked.
    #
    def self.optimal_distance(seq1, seq2, max_length)
      d = ( max_length * [seq1.size, seq2.size].min ) / ( max_length * 5 )
      d > 5 ? 5 : d
    end
    
  end
  
  #
  #  Template for the labeled html page is collection of patterns for labeled fields.
  #  For each field named 'foo' the JCore::Learner searches for tags <foo-label> </foo-label> 
  #  in the labeled html page and associates corresponding pattern with field 'foo' in the template
  # 
  class Template < Hash
    
    attr_accessor :modifiers  # which preprocess and modify the document
    attr_reader :xpath      # data that is extracted using xpath
    attr_reader :fields     # fields to be extracted e.g. :author, :title, :image, :text
    attr_reader :source     # news_story source
    attr_reader :max_length # max_length of the prefix or suffix pattern
    
    def initialize( fields, source = nil, max_length = 20 )
      raise ArguementError unless fields.is_a?(Array)
      @xpath = Hash.new
      @source = source
      @modifiers = Array.new
      @fields = fields.collect{ |x| x.to_sym }
      fields.each do |field|
        self[field] = Pattern.new
        @xpath[field] = Array.new
      end
      @max_length = max_length
    end
    #
    # Modify the doc before doing any extraction
    #
    def modify_doc( doc )
      return doc if modifiers.nil? || modifiers.empty?
      modifiers.each do |mod|
        doc = mod.apply( doc )
      end
      return doc
    end
    #
    # Matches the prefix sequence to the buffer sequence
    #
    def prefix_match(buf)
      each_pair do | field, pattern |
        suffix_map = pattern.suffix_map
        pattern.prefix.each do | prefix_pattern |
          yield( field, prefix_pattern, suffix_map[prefix_pattern] ) if Pattern.prefix_match( prefix_pattern, buf )
        end
      end
      return self
    end
    #
    #
    #
    def inspect
      "<Template:#{object_id} @source:#{source} @fields:[ #{fields.join(', ')} ]>"
    end
    #
    # Optimize Templates
    # This partitions the templates into group of same max_length and then merges each of them
    # Assumes the template.fields are same for each template.
    #
    def self.optimize_templates(templates)
      groups = templates.inject({}) do |hash, template|
        hash[template.max_length] ||= Array.new
        hash[template.max_length].push(template)
        hash
      end
      groups.keys.sort.collect{ |key| merge(groups[key]) }
    end
    #
    # Merging Templates - Templates must be of same max_length.
    #
    def self.merge(templates)
      return templates.first if templates.size < 2  
      fields = templates.first.fields
      max_length = templates.first.max_length
      merged_template = self.new( fields, "merged_#{max_length}", max_length )
      templates.each do |template|
        template.fields.each do |field|
          template.xpath[field].each { |path| merged_template.xpath[field].push(path) }
          template[field].prefix.each{ |prefix| merged_template[field].prefix.push(prefix) }
          template[field].suffix.each{ |suffix| merged_template[field].suffix.push(suffix) }
        end
      end
      return merged_template
    end
    #
    #
    #
    def self.serialize(data, file)
      File.open(file, 'wb') do |file|
        file << Marshal.dump(data)
      end
    end
    
    def self.load(file)
      object = nil;
      File.open(file, 'rb') do |file|
        object = Marshal.load(file.read)
      end
      return object
    end
    
  end
end