require 'rubygems'
# require 'mechanize'
require 'hpricot'

module JCore
  
  module Clean
    
    STOP_WORDS = {}
    SEPARATOR_WORDS = [ 'and', 'und', 'n' ]
    SEPARATORS = /[,\/&\|]/
    PUNCTUATIONS = /[\.\:\-\+]/
    
    # agencies - please store the names in capital letters
    AGENCIES = ( File.open( File.join( File.dirname(__FILE__), 'clean/AGENCIES' ) ).read.split(/(\n|\r)+/m).collect{ |x| x.strip } rescue [] )
    
    Dir[ File.join( File.dirname(__FILE__), 'clean/??.STOPWORDS' ) ].each do | file |
      language = File.basename(file)[0, 2].downcase
      STOP_WORDS[language] = File.open(file).read.split(/(\n|\r)+/m).collect! do |word|
        word = word.strip 
        # check if the stopword is regular expression starting and ending with /
        word[0] == 47 && word[-1] == 47 ? word[1..-2] : "(^|\\s+)#{word}(\\s+|$)"
      end
    end
    
    
    class << self
      
      def author( text, language = 'en')
        text = Hpricot(text.to_s).inner_text
        text.gsub!(/\(|\)|\]|\[|\}|\}/, ', ')  # removing parenthesis
        text.gsub!(/\s+/m, ' ')                # remove white space
        text.gsub!(/\d/, '')                   # remove the numbers
        text.strip!                            # remove trailing spaces
        (STOP_WORDS[language] || []).each{ |stop_word| text.gsub!(/#{stop_word}/i, ' ') }
        SEPARATOR_WORDS.each{ |word| text.gsub(/\s+#{word}\s+/i, ', ') }
        text.strip!              #remove trailing spaces
        results = text.split(JCore::Clean::SEPARATORS).collect{|x| x.gsub(JCore::Clean::PUNCTUATIONS, ' ').strip.gsub(/\s+/, ' ') }.select{ |x| !x.empty? && !JCore::Clean::AGENCIES.include?(x.upcase) }
        results.size > 1 ? results : results.first
      end
      
      #def keywords( story )
      #  doc = remote_keywords_response( story )
      #  (doc/"results/keywords/keyword").collect{ |x| x.inner_text }
      #end
      
      def story( text )
        text = Hpricot(text.to_s).inner_text
        text.gsub!(/\s+/m, ' ')
        return text
      end
      
      def headline( text )
        text = Hpricot(text.to_s).inner_text
        text.gsub!(/\&nbsp\;/, ' ')
        text.gsub!(/\s+/m, ' ')
        return text
      end
      
      def image( text, url = nil )
        img = (Hpricot(text.to_s)/"img:first").first
        img_url = img ? img.attributes['src'] : nil
        return nil if img_url.nil? || img_url.empty?
        img_url = URI.parse(img_url)
        img_url = URI.parse(url) + img_url if url&& img_url.relative?
        return img_url.to_s
      end
      
      
      protected
      
      # def remote_keywords_response( text )
      #   agent = WWW::Mechanize.new{ |a|
      #     a.user_agent_alias = 'Mac Safari'
      #   }
      #   page = agent.get( :url => 'http://access.alchemyapi.com/calls/text/TextGetKeywords', 
      #     :referer => 'http://access.alchemyapi.com/demo/entities_int.html', 
      #     :params => { 'apikey' => 'YOUR_API_KEY', 'text' => text }, :verb => :post 
      #   )
      #   Hpricot::XML(page.body)
      # end
      
      # def remote_ner_response( text )
      #   agent = WWW::Mechanize.new{ |a|
      #     a.user_agent_alias = 'Mac Safari'
      #   }
      #   page = agent.get( :url => 'http://access.alchemyapi.com/calls/text/TextGetRankedNamedEntities', 
      #     :referer => 'http://access.alchemyapi.com/demo/entities_int.html', 
      #     :params => { 'apikey' => 'YOUR_API_KEY', 'text' => text }, :verb => :post 
      #   )
      #   Hpricot::XML(page.body)
      # end
      
    end
    
    
  end
  
end