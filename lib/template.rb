module JCore
  
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
    
  end
  
  #
  #  Template for the labeled html page is collection of patterns for labeled fields.
  #  For each field named 'foo' the JCore::Learner searches for tags <foo-label> </foo-label> 
  #  in the labeled html page and associates corresponding pattern with field 'foo' in the template
  # 
  class Template < Hash
    
    attr_reader :fields     # fields to be extracted e.g. :author, :title, :image, :text
    attr_reader :source     # news_story source
    attr_reader :max_length # max_length of the prefix or suffix pattern
    
    def initialize( fields, source = nil, max_length = 20 )
      raise ArguementError unless fields.is_a?(Array)
      @source = source
      @fields = fields.collect{ |x| x.to_sym }
      fields.each do |field|
        self[field] = Pattern.new
      end
      @max_length = max_length
    end
    
    def inspect
      "<Template:#{object_id} @source:#{source} @fields:[ #{fields.join(', ')} ]>"
    end
    
    def serialize(file)
      File.open(file, 'wb') do |file|
        file << Marshal.dump(self)
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