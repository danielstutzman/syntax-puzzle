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
  stripe_points = %W[
    #{-width / 2},#{height + stroke_width / 2}
    #{skew - width / 2},#{-stroke_width / 2}
    #{skew + width / 2},#{-stroke_width / 2}
    #{width / 2},#{height + stroke_width / 2}
  ].join(' ')
  stripe_style = "fill:#{fill_color}"
  xml.polygon points:stripe_points, style: stripe_style
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
  xml.script(type: 'text/ecmascript') do
    xml.cdata! File.read('drag_elements.js')
  end

  xml.rect(x:0.5, y:0.5, width:399, height:199, fill:'none', stroke:'black')

#    
#    <rect class="draggable"
#          x="30" y="30"
#          width="80" height="80"
#          fill="blue"
#          transform="matrix(1 0 0 1 0 0)"
#          onmousedown="selectElement(evt)"/>
#          
#    <rect class="draggable"
#          x="160" y="50"
#          width="50" height="50"
#          fill="green"
#          transform="matrix(1 0 0 1 0 0)"
#          onmousedown="selectElement(evt)"/>
#
  # SW, NW, NE, SE
  skew_west = 15.0
  skew_east = 15.0
  height = 50.0
  width = 250.0
  font_height = 20.0
  west_padding = 20.0
  stroke_width = 1.0
  block_points = %W[
    0,#{height}
    #{skew_west},0
    #{width + skew_east},0
    #{width},#{height}
  ].join(' ')
  block_style = "fill:white; stroke:black; stroke-width:#{stroke_width}"

  xml.g transform: "translate(10 20)", class: "draggable", onmousedown: "selectElement(event)" do
    xml.polygon points:block_points, style: block_style
    stripe(xml, 'red', skew_west, height, stroke_width)
    xml.g transform: "translate(#{width} 0)" do
      stripe(xml, 'blue', skew_east, height, stroke_width)
    end
    xml.text('User', x:west_padding, y:(height/2 + font_height/2), class:'word')
  end
end
