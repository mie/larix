require File.join(File.dirname(__FILE__), 'post_base.rb')

class PostIndex < PostBase

    attr_reader :title, :url, :indexer_title

    def initialize
      @title = "index"
      @url = "#{@title}.html"
    end

    def paged_url(page)
      "#{@title}#{'-' + page.to_s if page > 0}.html"
    end

    def ==(another)
      true
    end

    def indexer_title
      nil
    end

    def l10n
      ""
    end
    
  end
