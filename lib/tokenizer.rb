require 'strscan'

module JCore  
  #
  # Rails HTML::Tokenizer Code with some modifications
  # You can fetch the current state of the tokenizer and 
  # And also reset the tokenizer to a particular state or default state.
  # It returns tokens rather than text.
  #
  class BaseTokenizer #:nodoc:
    
    # The current (byte) position in the text
    attr_reader :position
    
    # The current line number
    attr_reader :line
    
    # Create a new Tokenizer for the given text.
    def initialize(text)
      @scanner = StringScanner.new(text)
      @position = 0
      @line = 0
      @current_line = 1
    end

    # Return the next token in the sequence, or +nil+ if there are no more tokens in
    # the stream.
    def next
      return nil if @scanner.eos?
      @position = @scanner.pos
      @line = @current_line
      if @scanner.check(/<\S/) && @scanner.check(/<!?[^<>]*>/)
        Token.new(update_current_line(scan_tag).to_sym)
      else
        Token.new(:text, update_current_line(scan_text))
      end
    end
    
    def current_state
      { :position => @position, :line => @line, :current_line => @current_line, :scanner_position => @scanner.pos }
    end
    
    def reset(state=nil)
      state ||= { :position => 0, :line => 0, :current_line => 0, :scanner_position => 0 }
      @position = state[:position]
      @line = state[:line]
      @current_line = state[:current_line]
      @scanner.pos = state[:scanner_position]
    end
  
    private

      # Treat the text at the current position as a tag, and scan it. Supports
      # comments, doctype tags, and regular tags, and ignores less-than and
      # greater-than characters within quoted strings.
      def scan_tag
        tag = @scanner.getch
        if @scanner.scan(/!--/) # comment
          tag << @scanner.matched
          tag << (@scanner.scan_until(/--\s*>/) || @scanner.scan_until(/\Z/))
        elsif @scanner.scan(/!\[CDATA\[/)
          tag << @scanner.matched
          tag << (@scanner.scan_until(/\]\]>/) || @scanner.scan_until(/\Z/))
        elsif @scanner.scan(/!/) # doctype
          tag << @scanner.matched
          tag << consume_quoted_regions
        else
          tag << consume_quoted_regions
        end
        tag
      end

      # Scan all text up to the next < character and return it.
      def scan_text
        "#{@scanner.getch}#{@scanner.scan(/[^<]*/)}"
      end
      
      # Counts the number of newlines in the text and updates the current line
      # accordingly.
      def update_current_line(text)
        text.scan(/\r?\n/) { @current_line += 1 }
      end
      
      # Skips over quoted strings, so that less-than and greater-than characters
      # within the strings are ignored.
      def consume_quoted_regions
        text = ""
        loop do
          match = @scanner.scan_until(/['"<>]/) or break

          delim = @scanner.matched
          if delim == "<"
            match = match.chop
            @scanner.pos -= 1
          end

          text << match
          break if delim == "<" || delim == ">"

          # consume the quoted region
          while match = @scanner.scan_until(/[\\#{delim}]/)
            text << match
            break if @scanner.matched == delim
            text << @scanner.getch # skip the escaped character
          end
        end
        text
      end
  end
  
  #
  #  Default Tokenizer skips script, objects
  #
  #
  class Tokenizer <  BaseTokenizer
    
    Exceptions = { :'<script>' => :'</script>', :'<noscript>' => :'</noscript>', :'<object>' => :'</object>', :'<style>' => :'</style>', 
      :'<!---->' => true, :'<script/>' => true, :'<style/>' => true, :'<object/>' => true }
    
    def next
      token = super
      if token && Exceptions.has_key?( token.token )
        return self.next() if Exceptions[token.token] == true
        otoken = token
        while ( token = super )
          return self.next if Exceptions[ otoken.token ] == token.token
        end
      end
      return token
    end
    
  end
  
  # #
  # #
  # #
  # class Tokenizer < BaseTokenizer
  #   
  #   
  #   
  #   def next
  #     while ( token = super )
  #       return ( @current_token = token ) if Exceptions[ @current_token.token ] == token.token
  #     end if Exceptions.has_key?( @current_token ? @current_token.token : nil )
  #     @current_token = super
  #     @current_token && Exceptions[@current_token.token] == true ? next : @current_token
  #   end
  #   
  #   def current_state
  #     super.merge( :current_token => @current_token )
  #   end
  #   
  #   def reset(state=nil)
  #     super(state)
  #     state ||= { :current_token => nil }
  #     @current_node = state[:current_token ]
  #   end
  #   
  # end

end