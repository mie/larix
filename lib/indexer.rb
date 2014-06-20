require File.join(File.dirname(__FILE__), 'base.rb')

module Larix

  class Indexer

    using Larix::Base

    attr_reader :pages, :index

    def initialize(index, per_page)
      @index = index
      @per_page = per_page
      @pages = {}
    end

    def paginate(posts)
      @pages = posts.split_by(@index, @per_page)
    end

  end

end