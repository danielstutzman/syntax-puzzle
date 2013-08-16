require 'builder'

xml = Builder::XmlMarkup.new(target: STDOUT, indent: 2)

svg_attributes = {
  "xmlns:svg" => 'http://www.w3.org/2000/svg',
  xmlns: 'http://www.w3.org/2000/svg',
  version: '1.1',
  width: '400',
  height: '200',
}

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
  xml.text('User', x:10, y:30, class:'word')

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
  xml.book do
    xml.title 'here1'
    xml.author 'here2'
  end
end
