require 'builder'

TILE_HEIGHT = 50.0
FONT_HEIGHT = 20.0
CHAR_WIDTH  = 16.0
NBSP_UTF8   = "\xc2\xa0" # non-breaking space instead of space

xml = Builder::XmlMarkup.new(target: STDOUT, indent: 2)

svg_attributes = {
  "xmlns:svg" => 'http://www.w3.org/2000/svg',
  xmlns: 'http://www.w3.org/2000/svg',
  version: '1.1',
  width: '400',
  height: '200',
}

def tile_side_stripe(xml, fill_color, skew, stroke_width)
  width = 10
  # SW, NW, NE, SE
  points = %W[
    #{-width / 2},#{TILE_HEIGHT + stroke_width / 2}
    #{skew - width / 2},#{-stroke_width / 2}
    #{skew + width / 2},#{-stroke_width / 2}
    #{width / 2},#{TILE_HEIGHT + stroke_width / 2}
  ].join(' ')
  stripe_style = "fill:#{fill_color}"
  xml.polygon points:points, style: stripe_style
end

def tile_hole(xml, east_color, style)
  hole_w = CHAR_WIDTH * 3
  padding_north_south = 8
  height_multiplier =
    ((TILE_HEIGHT - padding_north_south * 2) / TILE_HEIGHT)
  skew_east = 15.0
  stroke_width = 1.0

  # NW, SW, SE, NE
  points = %W[
    0,#{padding_north_south}
    0,#{TILE_HEIGHT - padding_north_south}
    #{hole_w - skew_east*height_multiplier/2},#{TILE_HEIGHT - padding_north_south}
    #{hole_w + skew_east*height_multiplier/2},#{padding_north_south}
  ].join(' ')

  xml.polygon points:points, style:style

  xml.g transform:"translate(#{hole_w - 8} #{padding_north_south}) scale(#{height_multiplier} #{height_multiplier})" do
    tile_side_stripe xml, east_color, 15.0, stroke_width
  end
end

def tile(xml, x, y, text, west_color, east_color)
  do_skew_west = (west_color != nil)
  do_skew_east = (east_color != nil)
  skew_west = do_skew_west ? 15.0 : 0.0
  skew_east = do_skew_east ? 15.0 : 0.0
  west_padding = 20.0
  stroke_width = 1.0
  fill_color = 'white'
  stroke_color = 'black'
  width = west_padding + (CHAR_WIDTH * text.size) + west_padding

  # SW, NW, NE, SE
  points = %W[
    0,#{TILE_HEIGHT}
    #{skew_west},0
    #{width + skew_east},0
    #{width},#{TILE_HEIGHT}
  ].join(' ')
 
  style = %W[
    fill:#{fill_color};
    stroke:#{stroke_color};
    stroke-width:#{stroke_width}
  ].join(' ')

  xml.g transform:"translate(#{x} #{y})",
        class:"draggable word",
        onmousedown:"selectElement(event, this)" do

    xml.polygon points:points, style:style

    if do_skew_west
      tile_side_stripe xml, west_color, skew_west, stroke_width
    end

    if do_skew_east
      xml.g transform:"translate(#{width} 0)" do
        tile_side_stripe xml, east_color, skew_east, stroke_width
      end
    end

    xml.text text.gsub('_', NBSP_UTF8),
      x:west_padding, y:(TILE_HEIGHT/2 + FONT_HEIGHT/2)

    if text.include?('___')
      hole_x = west_padding + CHAR_WIDTH * text.index('___')
      xml.g transform:"translate(#{hole_x} 0)" do
        tile_hole xml, 'red', style
      end
    end
  end
end

xml.instruct!
xml.svg(svg_attributes) do
  xml.style do
    puts "
      .draggable {
        cursor: move;
      }
      .word {
        font-family: monospace;
        font-size: 20pt;
      }"
  end
  xml.script type: 'text/ecmascript' do
    xml.cdata! File.read('drag_elements.js')
  end

  xml.rect x:0.5, y:0.5, width:399, height:199,
           fill:'none', stroke:'black'
  tile xml, 10, 20, 'User', nil, '#ccf'
  tile xml, 10, 80, '.find(___)', '#ccf', 'green'
end
