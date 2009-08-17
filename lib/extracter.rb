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
            tokenizer_state = tokenizer.current_state
            prefixes = Hash.new
            template.prefix_match( buf.tokens ) do | field, prefix, suffixes |
              next if prefixes[ prefix ] # This prefix pattern has already met with success
              prefixes[ prefix ] = extract_field( field, suffixes, tokenizer, template, information )
              tokenizer.reset( tokenizer_state )
            end
          end
        end
      end
      #
      # Extracts data for a particular field
      #
      def extract_field( field, suffixes, tokenizer, template, information )
        suffix_buf = JCore::TokenBuffer.new( template.max_length )
        data_buf = Array.new
        possible_matches = Array.new
        index = -1
        attempts = 5 # We do not want to look for more than 5 matches.
        # As we are doing fuzzy suffix match using edit distance
        # We want to choose the best match score that is available
        while ( token = tokenizer.next )
          token.meta_id = ( index += 1 )
          suffix_buf.push( token ) if token.is_token?
          data_buf.push( token )
          suffixes.each do |suffix|
            if ( match = JCore::Pattern.suffix_match( suffix_buf.tokens, suffix, template.max_length ) )
              match.index =  ( suffix_buf.first.meta_id rescue 1 )
              possible_matches << match
            else
              break if !possible_matches.empty? && attempts == 0
              attempts += -1
            end
          end
          break if !possible_matches.empty? && attempts == 0
        end
        possible_matches.sort! # The first one after sorting contains the best information
        if possible_matches.any?
          data = data_buf[ 0...possible_matches.first.index ]
          # following is the obeservation:
          # information we look should not ideally contain lots of div elements. So if div elements match is higher than threshold the data should avoided
          ntokens = data.inject(0){ |sum, token| sum += ( token.start_tag? ? 1 : 0 ) }
          divtokens = data.inject(0){ |sum, token| sum += ( token.token == :"<div>" ? 1 : 0 ) }
          if divtokens.zero? || ( divtokens.to_f / ntokens < 0.25 ) 
            information.store( field, data.collect{ |x| x.to_s }.join( '' ) )
            return true
          end
        end
        return false
      end
    end
    
  end
  
end