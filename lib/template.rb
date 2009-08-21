module JCore

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