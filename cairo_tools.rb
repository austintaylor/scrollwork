require 'rubygems'
require 'active_support'
require 'homeschool'
require 'cairo'
require 'gdk_pixbuf2'
require File.join(File.dirname(__FILE__), "color")
require 'text_box'

class CairoTools
  attr_reader :surface, :cr, :height, :width
  
  def self.color(name, color)
    color = color.is_a?(String) ? Color::HSL.from_css(color) : Color::HSL.new(*color)
    define_method(name) {color}
    define_method(name.bang) {set_color(color)}
    @colors ||= {}
    @colors[name] = color
  end
  
  color :black, '000'
  color :white, 'FFF'
  
  def self.generate_image(path, *options)
    new.generate_image(path, options)
  end
  
  def self.generate(name, *options)
    generate_image(File.join(File.dirname(__FILE__), "../public/images", name), *options)
  end

  def self.preview(*options)
    return unless $0.match(/#{name.underscore}.rb$/)
    path = File.join(File.dirname($0), "generated.png")
    options = Array(yield) if block_given?
    generate_image(path, *options)
    `open #{path}`
    sleep 1
    File.unlink(path)
  end
  
  def generate_image(path, options)
    @width, @height = dimensions(*options)
    @surface = Cairo::ImageSurface.new(width, height)
    @cr = Cairo::Context.new(surface)
    paint_background
    draw(*options)
    cr.target.write_to_png(path)
  end
  
  def paint_background
    white!
    cr.paint
  end
  
  def outline(width=nil)
    cr.line_width = width if width
    yield
    cr.stroke
  end

  def circular_text(x, y, radius, font_size, text)
    radians = proc {|text| cr.set_font_size(font_size); cr.text_extents(text).x_advance/radius}
    blank = (2*Math::PI - radians[text])/2
    start = blank + Math::PI/2
    partial = ''
    text.split(//).each do |letter|
      theta = start + radians[partial]
      cr.move_to(x+radius*Math.cos(theta), y+radius*Math.sin(theta))
      cr.set_font_matrix Cairo::Matrix.identity.rotate(theta + Math::PI/2).scale(font_size, font_size)
      cr.show_text letter
      theta += radians[letter]
      partial << letter
    end
  end
  
  def create_text_box(x, y, width, height=nil, valign=:top)
    TextBox.new(cr, x, y, width, height, valign)
  end
  
  def draw_text_box(x, y, width, height=nil, valign=:top)
    tb = create_text_box(x, y, width, height, valign)
    yield tb
    tb.draw
  end
  
  def set_color(color)
    cr.set_source_rgb(*color.to_rgb.to_a)
  end
end

