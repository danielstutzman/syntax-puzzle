require 'builder'

xml = Builder::XmlMarkup.new(target: STDOUT, indent: 2)

xml.instruct!
xml.books do
  xml.book do
    xml.title 'here1'
    xml.author 'here2'
  end
end
