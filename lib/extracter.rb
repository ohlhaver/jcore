require 'rubygems'
require 'hpricot'
require 'htmlentities'
# begin
# require 'ruby-debug'
# rescue StandardError
# end

module JCore
  
  class DataHash < Hash
    
    def store( key, value )
      return super( key,value ) unless has_key?( key ) && fetch( key )
      old_value = fetch( key )
      new_value = case(old_value) when NilClass : value
      when Array : old_value
      else [ old_value ] end 
      if new_value.is_a?(Array)
        values = value.is_a?(Array) ? value : [ value ]
        values.each do | value |
          next if new_value.include?( value )
          new_value.push( value )
        end
      end
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
        # Apply all the modifications
        templates.each do |template|
          data = template.modify_doc( data )
        end
        tokenizer = JCore::Tokenizer.new( data )
        templates.each do |template|
          extract_information( tokenizer, template, information )
          tokenizer.reset
        end
        data = HTMLEntities.new.decode( data ) # decoding html entities
        doc = Hpricot( data )
        templates.each do |template|
          extract_xpath_information( doc, template, information )
        end
        return information
      end
      #
      #
      #
      def extract_xpath_information( doc, template, information )
        template.fields.each do |field|
          template.xpath[field].each do |xpath|
            begin
              xpath, options = xpath.is_a?(Array) ? xpath : [xpath, {}] 
              data = JCore::XPath.new( xpath, options ).match( doc )
              #puts data
              information.store( field, data ) if data && !data.empty?
            rescue StandardError => message
              puts message
            end
          end
        end
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
              prefixes[ prefix ].times do
                token = tokenizer.next 
                buf.push(token) if token && token.is_token? 
              end if prefixes[ prefix ] # Either false or Number of Tokens that needs to be skipped
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
          data_buf.push( token )
          if token.is_token?
            suffix_buf.push( token ) 
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
        end
        possible_matches.sort! # The first one after sorting contains the best information
        if possible_matches.any?
          data = data_buf[ 0...possible_matches.first.index ]
          # following is the obeservation:
          # information we look should not ideally contain lots of div elements. So if div elements match is higher than threshold the data should avoided
          ntokens = data.inject(0){ |sum, token| sum += ( token.start_tag? ? 1 : 0 ) }
          divtokens = data.inject(0){ |sum, token| sum += ( token.token == :"<div>" ? 1 : 0 ) }
          if divtokens.zero? || ( divtokens.to_f / ntokens <= 0.5 ) 
            information.store( field, data.collect{ |x| x.to_str }.join( '' ) )
            return possible_matches.first.index
          end
        end
        return false
      end
    end
    
  end
  
end