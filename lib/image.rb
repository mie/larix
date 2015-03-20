module Larix

  class Image

    SQUARE = 64

    attr_reader :thumbnail

    def initialize(filename)
      @bin = File.open(filename, 'r'){ |file| file.read }
      @thumbnail = Magick::ImageList.new.from_blob(@bin)
      @width = @thumbnail.columns.to_f
      @height = @thumbnail.rows.to_f
      crop_square
    end

    def crop_square
      vertical = 1 < @width/@height
      x = vertical ? ((@width - @height)/2).to_i : 0
      w = @width - 2*x
      y = vertical ? 0 : ((@height - @width)/2).to_i
      h = @height - 2*y
      # im = @image.copy
      @thumbnail.crop!(x,y,w,h)
      @thumbnail.resize!(SQUARE, SQUARE)
    end

    def save(output)
      @thumbnail.write(output)
    end

  end

end