#/usr/bin/env ruby

#
# Fetches Wikipedia's list of JS Bach compositions.
#

require 'json'
require 'nokogiri'
require 'open-uri'
require 'time'

DATABASE_FORMAT = 1
URL = "https://en.wikipedia.org/wiki/List_of_compositions_by_Johann_Sebastian_Bach"
TABLE_SELECTOR = "#TOP"
DROPPABLE_ROWS = 2

class Wikipedia
  def page
    @page ||= Nokogiri::HTML(open(URL))
  end

  def table
    @table ||= page.css("#{TABLE_SELECTOR}")
  end

  def header
    @header ||= table.css("th").map { |cell| cell.text }
  end

  def rows
    @rows ||= table.css("tr").map { |row| row.css("td").map { |cell| cell.text } }.
      drop(DROPPABLE_ROWS).select { |row| header.length == row.length }
  end

  def malformed_rows
    table.css("tr").map { |row| row.css("td").map { |cell| cell.text } }.
      drop(DROPPABLE_ROWS).select { |row| header.length != row.length }
  end
end

class Database
  def serialized
    {
      "format" => DATABASE_FORMAT,
      "compiled_at" => Time.now.to_s,
      "header" => @header,
      "rows" => @rows
    }
  end

  def json
    JSON.pretty_generate(serialized)
  end

  def write(filename)
    File.open(filename, "w") do |f|
      f << json
    end
  end

  def initialize(header, rows)
    throw ArgumentError, "all rows/header must be of same length" unless rows.all? { |row| header.length == row.length }

    @header = header
    @rows = rows
  end
end

def main
  w = Wikipedia.new
  d = Database.new(w.header, w.rows)
  d.write("compositions.json")
end

main
