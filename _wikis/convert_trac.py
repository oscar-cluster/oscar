#!/usr/bin/env ruby

# Convert Trac DB Wiki pages to Markdown source files

# This script is based on http://github.com/seven1m/trac_wiki_to_github which
# converted all pages from a Trac DB to GitHub Wiki format (as Textile).
#
# I made two changes:
# - uses MarkDown format instead
# - uses the sqllite3-ruby gem which does not need Ruby 1.9
#

TRAC_DB_PATH = '../trac.db'
OUT_PATH = 'wiki'
GITHUB_WIKI_URL = '/somebox/primospot/wikis/'

require 'rubygems'
gem 'sqlite3-ruby'
require 'sqlite3'

db = SQLite3::Database.new(TRAC_DB_PATH)
pages = db.execute('select name, text from wiki w2 where version = (select max(version) from wiki where name = w2.name);')

pages.each do |title, body|
  File.open(File.join(OUT_PATH, title.gsub(/\s/, '')+'.md'), 'w') do |file|
    body.gsub!(/\{\{\{([^\n]+?)\}\}\}/, '`\1`')
    body.gsub!(/\{\{\{(.+?)\}\}\}/m){|m| m.each_line.map{|x| "\t#{x}".gsub(/[\{\}]{3}/,'')}.join}
    body.gsub!(/\=\=\=\=\s(.+?)\s\=\=\=\=/, '### \1')
    body.gsub!(/\=\=\=\s(.+?)\s\=\=\=/, '## \1')
    body.gsub!(/\=\=\s(.+?)\s\=\=/, '# \1')
    body.gsub!(/\=\s(.+?)\s\=[\s\n]*/, '')
    body.gsub!(/\[(http[^\s\[\]]+)\s([^\[\]]+)\]/, '[\2](\1)')
    body.gsub!(/\!(([A-Z][a-z0-9]+){2,})/, '\1')
    body.gsub!(/'''(.+)'''/, '*\1*')
    body.gsub!(/''(.+)''/, '_\1_')
    body.gsub!(/^\s\*/, '*')
    body.gsub!(/^\s\d\./, '1.')
    file.write(body)
  end
end
