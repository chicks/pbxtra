#! /usr/bin/env ruby

require 'rubygems'
require 'pbxtra'

pbx             = PBXtra::Base.new("user", 'pass', {:debug => true})
ext             = 5555

start_date      = "2000-01-01"
end_date        = "2000-01-10"

csv             = pbx.get(:rep, {
  :showinbound  => :on,
  :showoutbound => :on,
  :showacd      => :on,
  :src          => :on,
  :dst          => :on,
  :disposition  => :on,
  :calldate     => :on,
  :duration     => :on,
  :clid         => :on,
  :csv          => :on,
  :for_ext      => ext,
  :reporting    => 1,
  :month1       => start_date.split(/-/)[1],
  :month2       => end_date.split(/-/)[1],
  :day1         => start_date.split(/-/)[2],
  :day2         => end_date.split(/-/)[2],
  :year1        => start_date.split(/-/)[0],
  :year2        => end_date.split(/-/)[0],
  :show_report_results => 1
})

puts csv
