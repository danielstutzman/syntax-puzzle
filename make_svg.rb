require 'builder'

xml = Builder::XmlMarkup.new(target: STDOUT, indent: 2)

svg_attributes = {
  "xmlns:svg" => 'http://www.w3.org/2000/svg',
  xmlns: 'http://www.w3.org/2000/svg',
  version: '1.1',
  width: '400',
  height: '200',
}

def stripe(xml, fill_color, skew, height, stroke_width)
  width = 10
  # SW, NW, NE, SE
  points = %W[
    #{-width / 2},#{height + stroke_width / 2}
    #{skew - width / 2},#{-stroke_width / 2}
    #{skew + width / 2},#{-stroke_width / 2}
    #{width / 2},#{height + stroke_width / 2}
  ].join(' ')
  stripe_style = "fill:#{fill_color}"
  xml.polygon points:points, style: stripe_style
end

def block(xml, width, height, text, do_skew_west, do_skew_east)
  skew_west = do_skew_west ? 15.0 : 0.0
  skew_east = do_skew_east ? 15.0 : 0.0
  font_height = 20.0
  west_padding = 20.0
  stroke_width = 1.0
  fill_color = 'white'
  stroke_color = 'black'

  # SW, NW, NE, SE
  points = %W[
    0,#{height}
    #{skew_west},0
    #{width + skew_east},0
    #{width},#{height}
  ].join(' ')
 
  style = %W[
    fill:#{fill_color};
    stroke:#{stroke_color};
    stroke-width:#{stroke_width}
  ].join(' ')

  xml.polygon points:points, style: style

  stripe xml, 'red', skew_west, height, stroke_width

  xml.g transform: "translate(#{width} 0)" do
    stripe xml, 'blue', skew_east, height, stroke_width
  end

  xml.text text, x:west_padding, y:(height/2 + font_height/2)
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

  xml.rect x:0.5, y:0.5, width:399, height:199, fill:'none', stroke:'black'

  xml.g transform: "translate(10 20)",
        class: "draggable word",
        onmousedown: "selectElement(event)" do
    block(xml, 250.0, 50.0, 'User', true, true)
  end
end
