require 'cairo_tools'
class Scrollwork < CairoTools
  def dimensions
    [200, 200]
  end
  
  def draw
    black!
    curve = Curve.new(cr)
    curve.logarithmic_spiral(100, 100, 360.deg * 2.4, 320.deg, 1, 0.18)
    curve.logarithmic_spiral(40, 132, 360.deg + 270.deg, -270.deg, 1, 0.23)
    curve.draw_outline
    # curve.debug
    
    b1 = Curve.new(cr)
    b1.logarithmic_spiral(115, 110, 360.deg * 1.4, 200.deg, 1, 0.18)
    b1 << curve[5]
    b1 << curve[6]
    b1.draw_outline
    
    b2 = Curve.new(cr)
    # b2.logarithmic_spiral(75, 95, 360.deg * 2.4, -100.deg, 1, 0.18)
    # b2.point 65, 90, 30.deg, 10
    b2.point 65, 95, 30.deg, 10, 12
    b2 << curve[2]
    b2 << curve[3]
    b2.draw_outline
    # b2.debug
  end
end

class Curve < Array
  attr_accessor :cr
  
  def initialize(cr)
    @cr = cr
  end
  
  def draw
    draw_control_points(self)
    cr.stroke
  end
  
  def draw_control_points(control_points)
    cr.move_to(*control_points.first.point)
    cx1, cy1 = control_points.first.leading_point
    control_points[1..-1].each do |point|
      cx2, cy2 = point.trailing_point
      cr.curve_to(cx1, cy1, cx2, cy2, point.x, point.y)
      cx1, cy1 = point.leading_point
    end
  end
  
  def offset_line(distance, flip)
    offset_line = self.map do |p|
      p.move_away_from_line(distance)
    end
    offset_line.each_with_index do |p, i|
      p.d1 *= (p.distance(offset_line[i-1])/self[i].distance(self[i-1])) * 1.1 unless i == 0
      p.d2 *= (p.distance(offset_line[i+1])/self[i].distance(self[i+1])) * 1.1 unless i + 1 == length
    end
    flip ? offset_line.map(&:flip).reverse : offset_line
  end
  
  def draw_outline
    draw_control_points(offset_line(-2, false) + offset_line(2, true))
    cr.stroke
  end
  
  def debug
    each do |point|
      cr.circle(point.x, point.y, 3)
      cr.fill
      cr.line_width = 1
      # cr.move_to(*point.trailing_point.map {|n| n + 2})
      cr.move_to(*point.trailing_point)
      cr.line_to(*point.leading_point)
      cr.stroke
    end
  end
  
  def point(x, y, theta, d1, d2=d1)
    p [x, y, theta, d1, d2]
    push(ControlPoint.new(x, y, theta, d1, d2))
  end
  
  def spiral(center_x, center_y, theta_one, delta_theta, phi, &algorithm)
    control_points_per_rotation = 8
    control_points = (control_points_per_rotation * delta_theta.abs / Math::PI / 2).to_i
    radians_between_points = delta_theta / (control_points-1)
    (0...control_points).each do |i|
      theta = theta_one + radians_between_points * i
      radius = algorithm.call(theta)
      x, y = center_x + radius * Math.cos(theta), center_y + radius * Math.sin(theta)
      tangent = theta + phi
      influence = radius * 0.285 * (delta_theta / delta_theta.abs)
      if i == control_points - 1
        point(x, y, tangent, influence, influence * 2)
      elsif i == 0
        point(x, y, tangent, influence * 3, influence)
      else
        point(x, y, tangent, influence)
      end
    end
  end
  
  def logarithmic_spiral(center_x, center_y, theta_one, delta_theta, a, b)
    spiral(center_x, center_y, theta_one, delta_theta, Math.atan(1/b)) do |theta|
      (a*Math::E)**(b*theta)
    end
  end
end

class ControlPoint
  attr_accessor :x, :y, :theta, :d1, :d2
  def initialize(x, y, theta, d1, d2=d1)
    @x, @y, @theta, @d1, @d2 = x, y, theta, d1, d2
  end
  
  def point
    [x, y]
  end
  
  def distance(point)
    Math.sqrt((x - point.x) ** 2 + (y - point.y) ** 2)
  end
  
  def trailing_point
    [x - d1 * Math.cos(theta), y - d1 * Math.sin(theta)]
  end
  
  def leading_point
    [x + d2 * Math.cos(theta), y + d2 * Math.sin(theta)]
  end
  
  def flip
    ControlPoint.new(x, y, theta + 180.deg, d2, d1)
  end
  
  def move_away_from_line(delta)
    ControlPoint.new(x + delta * Math.cos(theta - 90.deg) * d1/d1.abs, y + delta * Math.sin(theta - 90.deg) * d1/d1.abs, theta, d1, d2)
  end
end

class Numeric
  def deg
    self / 180.0 * Math::PI
  end
end

Scrollwork.preview