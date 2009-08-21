require 'lingua/stemmer'

module JCore
  
  # JCore::Tags module 
  module Keyword
    
    class << self
      
      def keywords(text, language='en')
        stemmer = Lingua::Stemmer.new(:language =>  language, :encoding => 'UTF_8')
        scanner = StringScanner.new(text)
        # remove the punctuation marks and special characters
        # remove or replace html entities
      end
      
    end
    
  end

end