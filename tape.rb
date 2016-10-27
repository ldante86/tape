#!/usr/bin/ruby -w
# encoding: utf-8

# a ppt(6) clone: encode text to 8-bit punched tape.
module Ppt

  SIDE, HOLE, PIN, SPACE, EDGE = '|', 'o', '.', ' ', '___________'

  def self.encode(str)
    0.upto(str.length-1) do |i|
      print SIDE
      7.downto(0) do |d|
        print PIN if d == 2
        ((str[i].ord & (1 << d)) != 0) ? print(HOLE) : print(SPACE)
      end
      ($show_text) ? printf("%s%*s\n", SIDE, 2, str[i]) : puts(SIDE)
    end
  end

end

$show_text = nil

if ARGV.first == "-t"
  $show_text = 1
  ARGV.shift
end

puts Ppt::EDGE
if ARGV.length > 0
  Ppt::encode(ARGV.join(Ppt::SPACE))
else
  while str = gets
    str = "\n" if str.length == 0
    Ppt::encode(str)
  end
end
puts Ppt::EDGE
