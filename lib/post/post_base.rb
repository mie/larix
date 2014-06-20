class PostBase

  attr_reader :title, :url, :indexer_title

  def initialize
    @title = "index"
    @url = "#{@title}.html"
  end

  def paged_url(page)
    raise NotImplementedError
  end

  def ==(another)
    raise NotImplementedError
  end

  def indexer_title
    raise NotImplementedError
  end

end