# encoding: UTF-8

require 'yaml'
require 'slim'
#require 'kramdown'
require 'redcarpet'
require 'time'
require 'fileutils'

class Tag

  attr_reader :name, :url

  def initialize(tag)
    @name = tag
    @url = "tag-#{tag}.html"
  end
  
  def ==(another)
    @name == another.name
  end

end

class YearMonth

  attr_reader :year, :month, :url, :name, :time, :day

  def initialize(time)
    @year, @month, @day = time.year, time.month, time.day
    @time = time
    @url = "#{month}-#{year}.html"
    @name = time.strftime("%B %Y")
  end
  
  def ==(another)
    @year == another.year && @month == another.month
  end

end

class Post

  attr_reader :title, :time, :time_utc, :tags, :md, :html, :url

  def initialize(text, url)
    lines = text.split("\n")
    @title = lines[0] ? lines[0].split('@title: ')[-1] : ""
    @time_utc = lines[1] ? Time.parse(lines[1].split('@time: ')[-1].to_s).utc : Time.now.utc
    @time = YearMonth.new(@time_utc)
    @tags = lines[2] && lines[2].split('@tags: ').size > 0 ? lines[2].split('@tags: ')[-1].split(%r{\s*\,\s*}).map {|t| Tag.new(t)} : []
    @md = lines.size > 3 ? lines[3..-1].join("\n") : ""
    @html = to_html(@md)
    @url = url || "#{@time.year}-#{@time.month}-#{safe_title}"
  end

  def html_url
    @url + '.html'
  end

  def template
    <<POST
@title: #{@title}
@time: #{@time_utc}
@tags:
POST
  end
  
  def name
    "#{@time.split()[0]}-#{safe_title}.html"
  end
  
  def safe_title
    st = @title.downcase.tr('^a-z', '')
    st.empty? ? 'post' : st
  end

  def to_html (markdown)
    #Kramdown::Document.new(markdown).to_html
    options = [ :autolink => true,
                :space_after_headers => true, 
                :no_intra_emphasis => true, 
                :lax_html_blocks => true, 
                :fenced_code_blocks => true ]
    renderer = Redcarpet::Render::HTML.new(:filter_html => true)
    md = Redcarpet::Markdown.new(renderer, *options )
    md.render(markdown)
  end

end

class Blog
  
  def initialize
    @dir = File.dirname(File.expand_path(__FILE__))
    config_file = File.join(@dir, 'config.yml')
    @config = YAML::load(File.open(config_file)) if File.exists?(config_file)
    @posts = []
    Dir.mkdir(File.join(@dir, @config['source_dir'])) unless File.directory?(File.join(@dir, @config['source_dir']))
    Dir.mkdir(File.join(@dir, @config['output_dir'])) unless File.directory?(File.join(@dir, @config['output_dir']))    
  end
  
  def new_post(title, url=nil)
    unless title.nil? || title == ''
      p = Post.new(title, url)
      path = File.join(@dir, @config['source_dir'], "#{p.url}.md")
      save(path, p.template)
      path
    end
  end

  def save(path, contents)
    File.open(path, "w:UTF-8") { |f|  f.write(contents) }
    path
  end
  
  def collect_posts
    Dir.glob(File.join(@dir, @config['source_dir'], '*.md')) do |post_file|
      File.open(post_file, "r:UTF-8") { |file|
        @posts.push(Post.new(file.read.to_s))
      }
    end
    @posts
  end

  def index_posts(field)
    _posts = {}
    if field == :time
      collect_posts.each { |post|
        try_find = _posts.keys == [] ? [] : _posts.keys.select{|k| k == post.time}
        year_month = try_find == [] ? post.time : try_find[0]
        _posts[year_month] = _posts.has_key?(year_month) ? _posts[year_month].push(post) : [post]
      }
    elsif field == :tags
      @posts.each { |post|
        tags = post.tags
        tags.each { |tag|
          try_find = _posts.keys == [] ? [] : _posts.keys.select{|k| k == tag }
          t = try_find == [] ? tag : try_find[0]
          _posts[t] = _posts.has_key?(t) ? _posts[t].push(post) : [post]
        }
      }
    elsif field == :title
      _posts['title'] = @posts
    end
    
    ipp = @config['posts_by_page'].to_i
    _posts.each { |k,v|
      v.sort!{ |x,y| y.time_utc <=> x.time_utc }
      paginated = []
      addit = v.size%ipp == 0 ? 0 : 1
      (v.size/ipp + addit).times { |i|
        paginated.push(v[(i*ipp)..((i+1)*ipp-1)])
      }
      _posts[k] = paginated
    }
    _posts
  end
  
  def generate
    theme = @config['theme']
    layout = File.open(File.join(@dir, 'themes', theme, "layout.slim"), "rb").read
    post_layout = File.open(File.join(@dir, 'themes', theme, "posts.slim"), "rb").read
    index_layout = File.open(File.join(@dir, 'themes', theme, "index.slim"), "rb").read
    
    clear
    
    l = Slim::Template.new { layout }
    
    [:time, :tags, :title].each { |indexer|
      index_posts(indexer).each { |index_name, pages|
        pages.each_with_index { |posts, i|
          i_name = indexer == :title ? "index.html" : index_name.url
          prev_url = i < (pages.size-1) ? index_url(i_name, i+1) : ''
          next_url = i > 0 ? index_url(i_name, i-1) : ''
          _p = Slim::Template.new { index_layout }.render(Object.new, 
                                                          :indexer => indexer, 
                                                          :index_name => index_name, 
                                                          :posts => posts, 
                                                          :pages => pages,
                                                          :i => i,
                                                          :next_url => next_url,
                                                          :prev_url => prev_url)
          out = l.render(Object.new, :config => @config){ _p }
          save(File.join(@dir, @config['output_dir'], index_url(i_name, i)), out)
        }
      }
    }
    
    @posts.each { |post|
      _p = Slim::Template.new { post_layout }.render(Object.new, :post => post)
      out = l.render(Object.new, :config => @config){ _p }
      save(File.join(@dir, @config['output_dir'], post.url), out)
    } unless @posts.size == 0
    
    ['css', 'js', 'img', 'font'].each { |catalog|
      FileUtils.cp_r(File.join(@dir, @config['theme_dir'], @config['theme'], catalog), File.join(@dir, @config['output_dir']))
    }
    
  end
  
  def index_url(index_name, count)
    count == 0 ? index_name : index_name[0...-5] + count.to_s + index_name[-5..-1] 
  end
      
  def clear
    output_dir = @config['output_dir']
    Dir.glob(File.join(@dir, output_dir, '**', '*.*')) do |f|
      File.delete(f) if File.file?(f) and f != '.' and f != '..'
    end
    Dir.glob(File.join(@dir, output_dir, '**', '*')) do |d|
      FileUtils.remove_dir(d) if File.directory?(d) and d != '.' and d != '..'
    end
  end
  
end

command = ARGV[0]
blog = Blog.new

case(command)
  when "post" then blog.new_post(ARGV[1], ARGV[2]) unless ARGV[1].nil?
  when "generate" then blog.generate
  else puts "exit"
end