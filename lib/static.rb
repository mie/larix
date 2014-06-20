require "yaml"
require "slim"
require "time"
require "fileutils"

# require "redcarpet"

require File.join(File.dirname(__FILE__), 'post.rb')
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
      @root = File.join(File.dirname(File.expand_path(__FILE__)), '..')
      @posts = []
      @indexers = []
    end

    def new_post(filename=nil,title=nil)
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
      index_layout = File.open(File.join(@root, @themes, @theme, "index.slim"), "rb").read

      l = Slim::Template.new { layout }

      clear

      posts.each { |post|
        _p = Slim::Template.new { post_layout }.render(Object.new, :post => post, :author => @author, :config => @config)
        out = l.render(Object.new, :title => post.title){ _p }
        save(File.join(@root, @output, "#{post.filename}.html"), out)
      }# unless @posts.size == 0

      index_posts.each { |indexer|
        indexer.pages.each{ |title, pages|
          pages.each_with_index { |posts, current_page|

            # p indexer.index, posts.size

            link = title.paged_url(current_page)
            prev_link = title.paged_url(current_page-1) if current_page > 0
            next_link = title.paged_url(current_page+1) if current_page < (pages.size-1)

            _p = Slim::Template.new { index_layout }.render(Object.new,
                                                            :config => @config,
                                                            :title => title,
                                                            :author => @author,
                                                            :posts => posts,
                                                            :current_page => current_page,
                                                            :num_pages => pages.size,
                                                            :indexer => indexer,
                                                            :next_page => next_link,
                                                            :prev_page => prev_link)
            out = l.render(Object.new, :title => @config['title']){ _p }
            save(File.join(@root, @output, link), out)
          }
        }
      }
      copy_assets

    end

  end

end