require "yaml"
require "slim"
require "time"
require "fileutils"
require "RMagick"

require File.join(File.dirname(__FILE__), 'post.rb')
require File.join(File.dirname(__FILE__), 'page.rb')
require File.join(File.dirname(__FILE__), 'image.rb')
require File.join(File.dirname(__FILE__), 'indexer.rb')

Dir[File.join(File.dirname(__FILE__), 'post', '*.rb')].each do |file|
  require file
end

module Larix

  class Static

    include Base

    INDEXES = ["index", "date", "section"]

    def initialize(config_file)
      file = File.expand_path(config_file)
      raise "no such config file: #{file}" unless File.exists?(file)
      @config = YAML.load_file(file)
      inst_vars(@config)
      @root = File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)), '..'))
      @posts = []
      @pages = []
      @indexers = []
      @static_dir = File.join(@root, @output)
      @source_dir = File.join(@root, @source)
      Dir.mkdir(@static_dir) unless File.exists?(@static_dir)
      Dir.mkdir(@source_dir) unless File.exists?(@source_dir)
    end

    def new_post(title='',filename=nil)
      post = Post.new(filename,title)
      new_file = File.join(@source, post.filename+'.md')
      File.open(new_file, 'w:UTF-8'){ |f|
        f.write(post.to_template)
      } unless File.exists?(new_file)
    end

    def posts
      return @posts unless @posts == []
      @posts = Dir.glob(File.join(@root, @source, '*.md')).map do |filename|
        Post.new(filename)
      end
      @posts
    end

    def pages
      return @pages unless @pages == []
      @pages = Dir.glob(File.join(@root, @source, 'pages', '*.md')).map do |filename|
        Page.new(filename)
      end
      @pages
    end

    def index_posts
      @indexers unless @indexers == []
      @indexers = INDEXES.map{ |k|
        i = Indexer.new(k, 20)
        i.paginate(@posts)
        i
      }
    end

    def build
      layout = File.open(File.join(@root, @themes, @theme, "layout.slim"), "rb").read
      post_layout = File.open(File.join(@root, @themes, @theme, "posts.slim"), "rb").read
      page_layout = File.open(File.join(@root, @themes, @theme, "page.slim"), "rb").read
      index_layout = File.open(File.join(@root, @themes, @theme, "index.slim"), "rb").read

      l = Slim::Template.new { layout }

      clear
      copy_assets

      pages.each { |page|
        _p = Slim::Template.new { page_layout }.render(Object.new, :page => page, :author => @author, :config => @config, :title => page.title, :pages => @pages)
        out = l.render(Object.new, :title => page.title){ _p }
        save(File.join(@root, @output, "#{page.filename}.html"), out)
      }

      posts.each { |post|
        _p = Slim::Template.new { post_layout }.render(Object.new, :post => post, :author => @author, :config => @config, :next_post => posts.index(post) == (posts.size-1) ? nil : posts[posts.index(post)+1], :prev_post => posts.index(post) == 0 ? nil : posts[posts.index(post)-1], :pages => @pages)
        out = l.render(Object.new, :title => post.title){ _p }
        save(File.join(@root, @output, "#{post.filename}.html"), out)
        if post.image
          image = Image.new(File.join(@source_dir, 'images', post.image))
          image.save(File.join(@static_dir, 'images', "thumb_#{post.image}"))
        end
      }

      index_posts.each { |indexer|
        indexer.pages.each{ |title, pgs|
          pgs.each_with_index { |posts, current_page|

            # p indexer.index, posts.size

            link = title.paged_url(current_page)
            prev_link = title.paged_url(current_page-1) if current_page > 0
            next_link = title.paged_url(current_page+1) if current_page < (pgs.size-1)

            _p = Slim::Template.new { index_layout }.render(Object.new,
                                                            :config => @config,
                                                            :title => title,
                                                            :author => @author,
                                                            :posts => posts,
                                                            :current_page => current_page,
                                                            :num_pages => pgs.size,
                                                            :indexer => indexer,
                                                            :next_page => next_link,
                                                            :prev_page => prev_link,
                                                            :pages => @pages)
            out = l.render(Object.new, :title => @config['title']){ _p }
            save(File.join(@root, @output, link), out)
          }
        }
      }

    end

  end

end