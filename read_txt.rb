TYPES = %w[ AR_RELATION AR_CLASS_OBJECT AR_OBJECT STRING SYMBOL ]

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

    puts line
  end

end
