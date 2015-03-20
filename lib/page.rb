require "redcarpet"
# require "kramdown"

module Larix

  class Page

    DELIMITER = '%%'

    attr_reader :filename, :title, :url

    def initialize(filename=nil,title='')
      @config = {'title' => title.to_s}
      @text = ''
      if filename && File.exists?(filename)
        source, @text = File.open(filename, 'r:UTF-8'){|f| f.read }.split(DELIMITER)
        @config = YAML.parse(source).to_ruby
      end
      @title = @config['title']
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
      
      # md = RDiscount.new(@text, :smart, :filter_html)
      # md.to_html

      # Kramdown::Document.new(@text).to_html
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

  end

end