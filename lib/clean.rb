require 'rubygems'
require 'hpricot'
require 'htmlentities'
require 'multibyte'

module JCore
  
  module Clean
    
    AUTHOR_STOP_WORDS = {}
    AUTHOR_SEPARATOR_WORDS = [ 'and', 'und', 'n' ]
    AUTHOR_SEPARATORS = /[,\/&\|]/
    AUTHOR_PUNCTUATIONS = /[\.\:\-\+]/
    ALL_PUNCTUATIONS = /[\@\!\"\#\$\%\&\^\'\(\)\{\}\[\]\;\:\<\>\.\,\|\?\/\\\+\=\_\-\*\~\`]/
    
    HE_CODER = HTMLEntities.new
    #
    # Converstion maps for accented chars to their equivalents
    # Starting from offset 128
    #
    EXTENDED_ASCII_MAP = [
       67, 117, 101,  97,  97,  97,  97, 99, 
      101, 101, 101, 105, 105, 105,  65, 65, 
       69,   [ 97, 101 ],     [ 65, 69], 111, 
      111, 111, 117, 117,  95,  79,  85, nil,
      nil,  95, 102,  97, 105, 111, 117, 110, 
      78 
    ]
    #
    # Converstion maps for accented chars to their equivalents
    # Starting from offset 222
    #
    EXTENDED_ASCII_MAP2 = [ nil, [115, 115] ]
    
    # agencies - please store the names in capital letters
    AUTHOR_AGENCIES = ( File.open( File.join( File.dirname(__FILE__), 'clean/AGENCIES' ) ).read.split(/(\n|\r)+/m).collect{ |x| x.strip } rescue [] )
    
    # LOADING AUTHOR STOP WORDS
    Dir[ File.join( File.dirname(__FILE__), 'clean/??.STOPWORDS' ) ].each do | file |
      language = File.basename(file)[0, 2].downcase
      AUTHOR_STOP_WORDS[language] = File.open(file).read.split(/(\n|\r)+/m).collect! do |word|
        word = word.strip 
        # check if the stopword is regular expression starting and ending with /
        word[0] == 47 && word[-1] == 47 ? word[1..-2] : "(^|\\s+)#{word}(\\s+|$)"
      end
    end
    
    
    class << self
      
      def pre_process( text, options = {} )
        text = HE_CODER.decode( text.to_s ).chars.normalize( :kd )
        text = Hpricot( text ).inner_text if options[:strip_tags]
        text = ascii( text ) if options[:ascii]
        text = remove_punctuation( text) if options[:punctuation] == false
        return text
      end
      
      # assumes it gets pre_process( text )
      def ascii( text )
        chars = text.unpack('U*')
        chars.collect! do |char| 
          case( char )
          when 0..127 : char
          when 128..221 : EXTENDED_ASCII_MAP[ char-128 ]
          when 222..255 : EXTENDED_ASCII_MAP2[ char-222 ]
          else nil end
        end
        chars.flatten!
        chars.delete_if{ |x| x.nil? }
        chars.pack('C*')
      end
      
      #
      def remove_punctuation( text )
        text.gsub!(ALL_PUNCTUATIONS, ' ')
        return text
      end 
      
      def author( text, language = 'en' )
        text = pre_process( text, :strip_tags => true )
        text.gsub!(/\(|\)|\]|\[|\}|\}/, ', ')  # removing parenthesis
        text.gsub!(/\s+/m, ' ')                # remove white space
        text.gsub!(/\d/, '')                   # remove the numbers
        text.strip!                            # remove trailing spaces
        (AUTHOR_STOP_WORDS[language] || []).each{ |stop_word| text.gsub!(/#{stop_word}/i, ' ') }
        AUTHOR_SEPARATOR_WORDS.each{ |word| text.gsub(/\s+#{word}\s+/i, ', ') }
        text.strip!              #remove trailing spaces
        results = text.split(AUTHOR_SEPARATORS).collect{|x| x.gsub(AUTHOR_PUNCTUATIONS, ' ').strip.gsub(/\s+/, ' ') }.select{ |x| !x.empty? && !AUTHOR_AGENCIES.include?(x.upcase) }
        results.size > 1 ? results : results.first
      end
      
      def story( text, langauge = 'en' )
        text = pre_process( text, :strip_tags => true )
        text.gsub!(/\s+/m, ' ')
        text.strip!
        return text
      end
      
      def headline( text, language = 'en' )
        text = pre_process( text, :strip_tags => true )
        text.gsub!(/\s+/m, ' ')
        text.strip!
        return text
      end
      
      def image( text, url = nil )
        doc = Hpricot(text.to_s)
        img = doc.root rescue nil
        img_url = img ? ( img.attributes['src'] || img.attributes['href'] ) : nil
        unless img_url
          img = ( doc/"img:first" ).first
          img_url = img ? img.attributes['src'] : nil
        end
        return nil if img_url.nil? || img_url.empty?
        img_url = URI.parse(img_url)
        img_url = URI.parse(url) + img_url if url&& img_url.relative?
        return img_url.to_s
      end
      
    end
    
    
  end
  
end