module JCore
  
  
  class XPathCommand
    
    attr_reader :xpath
    attr_reader :convert
    attr_reader :selection
    
    def initialize(text)
      @convert = 'inner_html'
      tokens = text.split(' ').uniq.select{|x| !x.empty? }
      @xpath = tokens.shift
      while( token = tokens.shift) 
        case (token) when 'first' : @selection = 'first'
        when 'to_s' : @convert = 'to_s' 
        end
      end
    end
    
    def match(doc)
      data = (doc/xpath).to_a
      result = data.collect{ |x| x.send( convert ) }
      result = result.send( selection ) if selection
      return result
    end
    
  end
  
  
  class XPath
    
    # Chain of fallback options
    attr_reader :xpaths
    
    def initialize(xpath)
      @xpaths = xpath.to_s.split(',').collect{ |x| JCore::XPathCommand.new(x.strip) }
    end
    
    def match(doc)
      xpaths.each do |xpath|
        result = xpath.match( doc )
        return( result ) if result && !result.empty?
      end
      return nil
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
    
    attr_reader :xpath      # data that is extracted using xpath
    attr_reader :fields     # fields to be extracted e.g. :author, :title, :image, :text
    attr_reader :source     # news_story source
    attr_reader :max_length # max_length of the prefix or suffix pattern
    
    def initialize( fields, source = nil, max_length = 20 )
      raise ArguementError unless fields.is_a?(Array)
      @xpath = Hash.new
      @source = source
      @fields = fields.collect{ |x| x.to_sym }
      fields.each do |field|
        self[field] = Pattern.new
        @xpath[field] = Array.new
      end
      @max_length = max_length
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