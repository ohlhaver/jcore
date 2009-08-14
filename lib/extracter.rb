module JCore
  
  class DataHash < Hash
    
    def store( key, value )
      return super( key,value ) unless has_key?( key ) && fetch( key )
      old_value = fetch( key )
      new_value = old_value.is_a?( Array ) ? ( old_value.include?( value ) ? old_value : old_value.push( value ) ) : ( old_value == value ) ? old_value : [ old_value, value ]
      super( key, new_value )
    end
    
  end
  #
  # Instance Based Information Extractor
  #
  module Extracter
    
    class << self
      #
      # Given a set of learned templates about the data source and unlabelled data, this method
      # extracts the meaningful information from the templates and returns a DataHash object
      #
      def extract( data, templates )
        templates = [ templates ] if templates.is_a?( JCore::Template )
        raise ArguementError unless templates.is_a?( Array )
        information = DataHash.new
        tokenizer = JCore::Tokenizer.new( data )
        templates.each do |template|
          extract_information( tokenizer, template, information )
          tokenizer.reset
        end
        return information
      end
      #
      # Extracts information from one template
      #
      def extract_information( tokenizer, template, information )
        buf = JCore::TokenBuffer.new( template.max_length )
        while ( token = tokenizer.next )
          if token.is_token? # token should be pushed to the prefix buffer stream
            buf.push( token ) 
            field, suffix = template.prefix_match( buf.tokens )
            if field
              tokenizer_state = tokenizer.current_state
              extract_field(field, suffix, tokenizer, template, information)
              tokenizer.reset( tokenizer_state )
            end
          end
        end
      end
      #
      # Extracts data for a particular field
      #
      def extract_field( field, suffix, tokenizer, template, information )
        suffix_buf = JCore::TokenBuffer.new( template.max_length )
        data_buf = Array.new
        possible_matches = Array.new
        index = -1
        attempts = 5 # We do not want to look for more than 5 matches.
        while ( token = tokenizer.next )
          token.meta_id = ( index += 1 )
          suffix_buf.push( token ) if token.is_token?
          data_buf.push( token )
          if ( match = JCore::Pattern.suffix_match( suffix_buf.tokens, suffix, template.max_length ) )
            match.index =  ( suffix_buf.first.meta_id rescue 1 )
            possible_matches << match
          else
            break if !possible_matches.empty? && attempts == 0
            attempts += -1
          end
        end
        possible_matches.sort! # The first one after sorting contains the best information
        information.store( field, data_buf[ 0...possible_matches.first.index ].collect{ |x| x.to_s }.join( '' ) ) if possible_matches.any?
      end
      
    end
    
  end
  
end