module JCore
  #
  # Stores tokens array separately
  #
  class TokenBuffer < Array
    
    attr_reader :tokens
    attr_reader :capacity
    
    def initialize(capacity = -1)
      @tokens = Array.new
      @capacity = capacity
      super(0)
    end
    
    def push(item)
      shift if size == capacity
      @tokens.push(item.token)
      super(item)
    end
    
    def shift
      @tokens.shift
      super()
    end
    
    def full?
      size == capacity
    end
    
  end
  #
  # JCore::Token objects are returned by the JCore::Tokenizer
  #
  class Token
    
    Exceptions = [:'<img>', :'<img/>']

    attr_reader :token
    attr_reader :label
    attr_reader :tag_type
    attr_accessor :meta_id
    attr_reader :text

    def initialize( token, text = nil )
      @token = core_token(token)
      @label = extract_label(@token)
      @tag_type = extract_tag_type(@token)
      @text = (text || token.to_s)
    end
    #
    # All those tokens which we want to include in the 
    # prefix and suffix patterns 
    #
    def is_token?
      token != :text
    end
    # If it is modifier block
    def modifier?
      label == :'modify-doc'
    end
    #
    # If it is user annotated label
    # All user annotated labels are of the form <\w+-label>
    # e.g. <author-label></author-label>
    #
    def is_label?
      label != nil
    end
    #
    # Opening tags like <div> <span>
    #
    def start_tag?
      tag_type == :opening
    end
    #
    # Closing tags e.g. </div> </span>
    #
    def end_tag?
      tag_type == :closing
    end
    #
    # Auto Closing tags e.g. <br/>, <div />
    #
    def autoclosing_tag?
      tag_type == :autoclosing
    end
    #
    # For irb
    #
    def inspect
      "#{token}#{ ": #{text}" unless self.empty? }"
    end
    #
    #
    #
    def to_str
      is_token? && !Exceptions.include?(token) ? token.to_s : text.to_s
    end
    #
    #
    #
    def to_s
      text.to_s
    end
    #
    # If labeled attribute has xpath with it
    #
    def xpath
      attr_value('xpath')
    end
    
    def attr_value(name)
      match = text.match(/#{name}\W*=\W*"([^"]+)"/) || text.match(/#{name}\W*=\W*'([^']+)'/)
      match ? match[1] : nil
    end
    
    protected
    #
    # Extracts the core token
    # e.g. <div id="123"> is reduced to <div>
    #
    def core_token(token)
      start_match = token.to_s.match(/(<!?\/?[\w\-]+)/)
      end_match = token.to_s.match(/((\-\-)?(\/)?>)/)
      t = (start_match ? "#{start_match[1]}#{end_match[1]}" : token.to_s)
      ( t.match(/<!\-\-.+\-\->/) ? '<!---->' : t ).downcase.to_sym
    end
    #
    # Extracts the label from the token
    # e.g. for <author-label> :author is returned
    #
    def extract_label(token)
      label = token.to_s.match(/<\/?(.+)-label\W*\/?>/)
      label = label[1].to_sym if label
      label = :'modify-doc' if label.nil? && token.to_s.match(/<\/?modify-doc\W*>/)  
      return label
    end
    #
    # Extracts the tag type from the token
    # e.g  <foo> is opening tag
    #      <foo/> is auto-closing tag
    #      </foo> is closing tag
    #
    def extract_tag_type(token)
      token = token.to_s
      tag_type = :closing if token.match(/<\/.+>/)
      tag_type = :autoclosing if token.match(/<.+\/>/)
      tag_type = :opening if token.match(/<[^\/]+>/)
      return tag_type
    end

  end
end