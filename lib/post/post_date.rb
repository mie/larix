require File.join(File.dirname(__FILE__), 'post_base.rb')

class PostDate < PostBase

  attr_reader :year, :month, :day, :url, :title, :time

  def initialize(time)
    if time.class == String
      @time = Time.parse(time).utc
    else
      @time = time
    end
    @year, @month, @day = @time.year, @time.month, @time.day
    # @time = time
    @url = "#{month}-#{year}.html"
    @name = @time.strftime("%B %Y")
  end
  
  def paged_url(page)
    "#{@month}-#{@year}#{'-' + page.to_s if page > 0}.html"
  end

  def ==(another)
    @year == another.year && @month == another.month
  end

  def <=>(another)
    @year <=> another.year && @month <=> another.month
  end

  def l10n_date
    "#{@day} #{['января', 'февраля' , 'марта', 'апреля', 'мая' , 'июня', 'июля', 'августа' , 'сентября', 'октября', 'ноября' , 'декабря'][@month-1]} #{@year}"
  end

  def l10n
    "#{['Январь', 'Февраль' , 'Март', 'Апрель', 'Май' , 'Июнь', 'Июль', 'Август' , 'Сентябрь', 'Октябрь', 'Ноябрь' , 'Декабрь'][@month-1]} #{@year}"
  end

  def indexer_title
    "Посты за "
  end

end
