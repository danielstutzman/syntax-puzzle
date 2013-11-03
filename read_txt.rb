require 'builder'

TYPES = %w[ AR_RELATION AR_CLASS_OBJECT AR_OBJECT STRING SYMBOL ]

TILE_HEIGHT = 50.0
FONT_HEIGHT = 20.0
CHAR_WIDTH  = 16.0
NBSP_UTF8   = "\xc2\xa0" # non-breaking space instead of space
TYPE_TO_COLOR = {
  AR_CLASS_OBJECT: '#ccf',
  AR_RELATION:     '#ccf',
  AR_OBJECT:       'blue',
  INT:             'red',
  STRING:          'green',
  SYMBOL:          'yellow',
}
BACKGROUND_COLOR = '#eee'
STROKE_WIDTH = 1.0
STROKE_COLOR = 'black'

xml = Builder::XmlMarkup.new(target: STDOUT, indent: 2)

svg_attributes = {
  "xmlns:svg" => 'http://www.w3.org/2000/svg',
  xmlns: 'http://www.w3.org/2000/svg',
  version: '1.1',
  onmousemove: 'if (selectedElement) { moveElement(event); }',
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

def tile_hole(xml, east_color)
  hole_w = CHAR_WIDTH * 3
  padding_north_south = 8
  height_multiplier =
    ((TILE_HEIGHT - padding_north_south * 2) / TILE_HEIGHT)
  skew_east = 15.0

  style = %W[
    fill:#{BACKGROUND_COLOR};
    stroke:#{STROKE_COLOR};
    stroke-width:#{STROKE_WIDTH}
  ].join(' ')

  # NW, SW, SE, NE
  points = %W[
    0,#{padding_north_south}
    0,#{TILE_HEIGHT - padding_north_south}
    #{hole_w - skew_east*height_multiplier/2},#{TILE_HEIGHT - padding_north_south}
    #{hole_w + skew_east*height_multiplier/2},#{padding_north_south}
  ].join(' ')

  xml.polygon points:points, style:style

  xml.g transform:"translate(#{hole_w - 8} #{padding_north_south}) scale(#{height_multiplier} #{height_multiplier})" do
    tile_side_stripe xml, east_color, 15.0, STROKE_WIDTH
  end
end

def tile(xml, x, y, text, west_type, east_type, east_hole_type)
  do_skew_west = (west_type != nil)
  do_skew_east = (east_type != nil)
  skew_west = do_skew_west ? 15.0 : 0.0
  skew_east = do_skew_east ? 15.0 : 0.0
  west_padding = 20.0
  fill_color = 'white'
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
    stroke:#{STROKE_COLOR};
    stroke-width:#{STROKE_WIDTH}
  ].join(' ')

  xml.g transform:"translate(#{x} #{y})",
        class:"draggable word",
        onmousedown:"selectElement(event, this)" do

    xml.polygon points:points, style:style

    if do_skew_west
      west_color = TYPE_TO_COLOR[west_type]
      tile_side_stripe xml, west_color, skew_west, STROKE_WIDTH
    end

    if do_skew_east
      xml.g transform:"translate(#{width} 0)" do
        east_color = TYPE_TO_COLOR[east_type]
        tile_side_stripe xml, east_color, skew_east, STROKE_WIDTH
      end
    end

    xml.text text.gsub('_', NBSP_UTF8),
      x:west_padding, y:(TILE_HEIGHT/2 + FONT_HEIGHT/2)

    if text.include?('___')
      hole_x = west_padding + CHAR_WIDTH * text.index('___')
      xml.g transform:"translate(#{hole_x} 0)" do
        east_hole_color = TYPE_TO_COLOR[east_hole_type]
        tile_hole xml, east_hole_color
      end
    end
  end
end

tiles = []
File.open('241.txt') do |file|
  file.each_line do |line|
    west_type = nil
    TYPES.each do |type|
      if line.start_with?(type)
        west_type = type
        line = line[type.size..-1]
      end
    end

    east_type = nil
    TYPES.each do |type|
      if line.end_with?(" => #{type}\n")
        east_type = type
        line = line[0...(line.length - type.length - 5)]
      end
    end

    east_hole_type = nil
    TYPES.each do |type|
      if line.include?(type)
        east_hole_type = type
        line = line.gsub(type, '___')
      end
    end

    tiles.push({
      text: line,
      west_type: west_type ? west_type.intern : nil,
      east_type: east_type ? east_type.intern : nil,
      east_hole_type: east_hole_type ? east_hole_type.intern : nil,
    })
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

  xml.rect x:0, y:0, width:'100%', height:'100%', fill:BACKGROUND_COLOR
  y = 20
  tiles.each do |tile|
    tile xml, 10, y, tile[:text], tile[:west_type], tile[:east_type],
      tile[:east_hole_type]
    y += 60
  end
end


