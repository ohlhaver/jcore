module JCore
  
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
      score = JCore::Distance.edit_distance(seq1, seq2)
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
    # Something that may be tweaked.
    #
    def self.optimal_distance(seq1, seq2, max_length)
      d = ( max_length * [seq1.size, seq2.size].min ) / ( max_length * 5 )
      d > 5 ? 5 : d
    end
    
  end
  
end