require 'rubygems'
require 'lingua/stemmer'
require File.join(File.dirname(__FILE__), 'clean')

module JCore
  
  # JCore::Tags module 
  module Keyword
    
    KEYWORD_STOPWORDS = {}
    #
    # LOADING KEYWORD STOP WORDS
    #
    Dir[ File.join( File.dirname(__FILE__), 'keywords/??.STOPWORDS' ) ].each do | file |
      language = File.basename(file)[0, 2].downcase
      KEYWORD_STOPWORDS[language] = File.open(file).read.split(/(\n|\r)+/m).collect do |word|
        word.strip
      end.select{ |word| !word.empty? }.uniq
    end
    
    class << self
      #
      # assumes the text is already preprocessed i.e. story information has already
      # extracted and cleaned. so we can directly just convert the text to ascii
      # remove punctuation marks and then generate stems for each word and remove
      # the stop words
      #
      def keywords(text, language='en')
        stemmer = Lingua::Stemmer.new(:language =>  language, :encoding => 'UTF_8')
        text.downcase! # downcase all letters
        text = JCore::Clean.ascii( text ) # convert to ascii
        text = JCore::Clean.remove_punctuation( text ) # remove punctuation
        text.gsub!(/\s+/m, ' ') # remove whitespace
        text.gsub!(/\d+/, '') # remove digits
        text.strip!
        words = text.split(' ').collect{ |word| stemmer.stem(word) } # stem words
        words.uniq! # remove duplicates
        words - KEYWORD_STOPWORDS[language].to_a # remove stop words
      end
      #
      # similarity check using bigrams and unigrams over stemmed keywords
      # 
      def similar?(keywords1, keywords2, options={})
        score = similarity_score( keywords1, keywords2 )
        minimum = keywords1.size > keywords2.size ? keywords2.size : keywords1.size
        minimum = 1 if minimum.zero?
        (score * 100 / minimum) >= 8  # Threshold value is something that needs to be tweaked
      end
      #
      # similarity score uses bigrams and unigrams over stemmed keywords
      # Bigrams are consecutive word groups
      # e.g. 
      # let keywords of sentence "movie the lord of the rings is a hit."
      # be "movie", "lord", "rings", "hit" in occurence order will have 
      # three bigrams "movie lord", "lord rings", "rings hit"
      #
      def similarity_score(keywords1, keywords2, options={})
        count_1gram = count_common( keywords1, keywords2 )
        count_2gram = count_common( grams( keywords1, 2 ), grams( keywords2, 2) )
        Math.sqrt( count_2gram * count_1gram ).ceil
      end
      #
      # returns number of words which are common to keywords1 and keywords2 array
      #
      def count_common( keywords1, keywords2, options = {} )
        if options[:length]
          keywords1 = keywords1[0...options[:length]]
          keywords2 = keywords2[0...options[:length]]
        end
        common_word_count = keywords1.inject(0){ |s,x| s = keywords2.include?(x) ? s+1 : s }
        #total_word_count = keywords1.size + keywords2.size - common_word_count
        #min_size = keywords1.size < keywords2.size ? keywords1.size : keywords2.size
        #[ common_word_count, common_word_count.to_f / min_size, common_word_count.to_f / total_word_count ]
      end
      #
      # create groups of words
      #
      def grams( array, number )
        result = array.dup
        index = 0
        (number-1).times do 
          start_index = index
          result.collect!{ |x| index += 1; "#{x} #{array[index]}"}
          result.pop
          index = start_index + 1
        end
        return result
      end
      
      def common( keywords1, keywords2 )
        keywords1.inject([]){ |s,x| s = keywords2.include?(x) ? s.push(x) : s }
      end
      
    end
    
  end

end