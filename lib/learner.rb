module JCore
  
  #
  # Instance Based Template Learner 
  #
  module Learner
    
    class << self
      
      #
      # Given a blank template and labeled data, this method
      # populates the template with field patterns and returns the
      # template. Template provided is modified.
      #
      def learn(annotated_data, template)
        buf = Array.new # Prefix Token Buffer Stream
        tokenizer = Tokenizer.new(annotated_data)
        while (token = tokenizer.next)
          if token.is_label?
            if token.start_tag? && template.fields.include?( token.label )
              store_prefix_pattern_for(token.label, template, buf) # storing prefix pattern
              tokenizer_state = tokenizer.current_state # storing the current state of tokenizer
              store_suffix_pattern_for(token.label, template, tokenizer) # storing suffix pattern
              tokenizer.reset(tokenizer_state) # reseting the current state of tokening
            end
          elsif token.is_token?
            buf.push(token) # token should be pushed to the prefix buffer stream
          end
          buf.shift if buf.size > template.max_length # Pop out oldest token if buffer is full
        end
        return template
      end
      
      protected
      
      # Given the label, prefix buffer and template
      # Template is updated with the prefix pattern for the label
      def store_prefix_pattern_for(label, template, buf)
        buf.shift if buf.size > template.max_length
        template[label].prefix.push buf.collect{ |x| x.token }
        # puts template[label].prefix.collect{|x| x.join(", ")}.join(', ')
      end
      
      
      # Given the label, tokenizer and template
      # Template is updated with the suffix pattern for the label
      def store_suffix_pattern_for(label, template, tokenizer)
        buf = Array.new
        start_counting = false
        while (token = tokenizer.next)
          if start_counting
            buf.push(token) if token.is_token? && !token.is_label?
            break if buf.size == template.max_length
          else
            start_counting = true if token.is_label? && token.label == label && token.end_tag?
          end
        end
        template[label].suffix.push buf.collect{ |x| x.token }
        # puts template[label].suffix.collect{|x| x.join(", ")}.join(', ')
      end
      
    end
    
  end
  
end