require File.join(File.dirname(__FILE__), 'post_base.rb')

class PostSection < PostBase

  attr_reader :title, :url, :indexer_title

  def initialize(s)
    @title = s
    @url = "section-#{s}.html"
  end

  def paged_url(page)
    "section-#{@title}#{'-' + page.to_s if page > 0}.html"
  end
  
  def ==(another)
    @title == another.title
  end

  def l10n
    @title
  end

  def indexer_title
    "Посты по тэгу "
  end

end