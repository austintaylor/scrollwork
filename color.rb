module Color
  def rgb(*args)
    RGB.new(*args)
  end
  
  def hsl(*args)
    HSL.new(*args)
  end
  
  class Base
    def self.inherited(subclass)
      subclass.name.sub('Color::', '').downcase.split(//).map(&:to_sym).each_with_index do |component, i|
        define_method(component) do
          @components[i]
        end
        define_method(component.writer) do |x|
          @components[i] = constrain(x)
        end
      end
    end
    
    def initialize(*components)
      @components = components.map(&method(:constrain))
    end
    
    def to_a
      @components
    end
    
    def -(other)
      self + other.to_a.map(&:-@)
    end
    
    def +(other)
      other_array = other.to_a
      array = component_indicies.map {|i| @components[i] + other_array[i]}
      self.class.new(*array)
    end
    
    def ==(other)
      (other.class == self.class || other.class == Array) && component_indicies.all? {|i| epsilon(@components[i] - other.to_a[i])}
    end
    
    protected
    def component_indicies
      (0..@components.size - 1).to_a
    end
    
    def epsilon(x)
      x.abs <= 0.01
    end
    
    def constrain(x)
      x > 1.0 ? 1.0 : x < 0.0 ? 0.0 : x
    end
  end
  
  class RGB < Base
    def self.from_css(string)
      string.gsub!('#', '')
      new(*string.split(//).in_groups_of(string.length/3).map {|a| a.join.to_i(16).to_f / (16 ** (string.length/3) - 1).to_f})
    end
    
    def to_hsl(debug=false)
      max = @components.max
      min = @components.min
      compute_hue = proc do |numerator, degrees|
        degrees(60) * (numerator / (max - min)) + degrees(degrees)
      end
      l = (max + min)/2.0
      s = (epsilon(l) || epsilon(max - min)) ? 0 :
        l <= 0.5 ? (max - min) / (max + min) :
          (max - min) / (2 - (max + min))
      h = epsilon(max - min) ? 0 :
          max == r ? compute_hue[g - b, g >= b ? 0 : 360] :
          max == g ? compute_hue[b - r, 120] :
                     compute_hue[r - g, 240]
      HSL.new(h, s, l)
    end
    
    def to_css
      "#" + ("%02X" * 3 % @components.map {|c| c * 255})
    end
    
    protected
    def degrees(x)
      x.to_f/360.0
    end
  end
  
  class HSL < Base
    def self.from_css(string)
      RGB.from_css(string).to_hsl(true)
    end
    
    def to_rgb
      return RGB.new(l, l, l) if epsilon(s)
      q = l < 0.5 ? l * (1.0 + s) : (l + s) - l * s
      p = 2 * l - q
      tc = [h + 1.0/3.0, h, h - 1.0/3.0]
      tc.map! do |x|
        x < 0 ? x + 1.0 :
          x > 1.0 ? x - 1.0 : x
      end
      rgb = tc.map do |tc|
        tc < 1.0/6.0 ? p + ((q - p) * 6.0 * tc) :
        tc < 3.0/6.0 ? q :
        tc < 4.0/6.0 ? p + ((q - p) * 6.0 * (2.0/3.0 - tc)) : p
      end
      RGB.new(*rgb)
    end
    
    def to_css
      to_rgb.to_css
    end
  end
end