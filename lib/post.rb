require "redcarpet"

module Larix

  class Post

    DELIMITER = '%%'

    attr_reader :filename, :title, :url, :date

    def initialize(filename=nil,title='')
      @config = {'title' => title.to_s, 'date' => Time.now.utc, 'section' => 'general'}
      @text = ''
      if filename && File.exists?(filename)
        source, @text = File.open(filename, 'r:UTF-8'){|f| f.read }.split(DELIMITER)
        @config = YAML.parse(source).to_ruby
      end
      @config.each{ |k,v|
        name = "@#{k.downcase}"
        if k.to_s == 'title'
          instance_variable_set(name, v)
        else
          instance_variable_set(name, Object.const_get("Post#{k.to_s.capitalize}").new(v))
        end
      }
      @filename = (File.basename(filename, '.md') if filename) || safe_text(@title)
      @url = "#{@filename}.html"
    end

    def to_html
      options = [ :autolink => true,
                  :space_after_headers => true, 
                  :no_intra_emphasis => true, 
                  :lax_html_blocks => true, 
                  :fenced_code_blocks => true ]
      renderer = Redcarpet::Render::HTML.new(:filter_html => true)
      md = Redcarpet::Markdown.new(renderer, *options )
      md.render(@text)
    end

    def to_template
  template=<<PST
#{@config.to_yaml}
#{DELIMITER}
#{@text}
PST
    end

    def safe_text(t)
      st = t.downcase.tr('^a-z0-9-', '')
      st.empty? ? "post-#{Time.now.to_i}" : st
    end

    # #section and #date methods are needed for indexing and comparison
    # For 'section' we can simply use its name, for 'time' - both month and year
    # in a representation as a String
    # Other possible indexers should be included in @config and have a getter
    # method with a corresponing method name

    def section
      @section
    end

    def date
      # "#{@date.month}-#{@date.year}"
      @date
    end

    # Fake method to collect all posts using same technique

    def index
      PostIndex.new
    end

    def <=>(another)
      another.date <=> date
    end

  end

end