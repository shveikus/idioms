require 'pry'
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'ruby-progressbar'

URI_BASE = 'https://www.skypeenglishclasses.com/english-phrasal-verbs/'.freeze

page = Nokogiri::HTML(open(URI_BASE))

hashes_with_phrasal_verbs = page.css('#content div.content-text table tbody tr')
                                .map do |elem|
  name = if elem.css('td a').text.empty?
           elem.css('td')[0].text
         else
           elem.css('td a').text
         end

  {
    name: name,
    link: elem.css('td a').map { |a| a['href'] }.first
  }
end

# removing title of the table
hashes_with_phrasal_verbs.shift

total_verbs = hashes_with_phrasal_verbs.length

threads = []

@result = []

@progressbar = ProgressBar.create(format: '%a |%b>>%i| %p%% %t', total: total_verbs)

def get_conjugate(page)
  page.css('main div div div ul').children.select(&:element?).map(&:text)
end

def get_definitions(page)
  arr_of_sentences = page.css('main div div div div p').map(&:text)
  begin
    arr_of_sentences.pop if arr_of_sentences.last.match(/^See/)
  rescue NoMethodError
    arr_of_sentences = page.css('main div div div div').map(&:text)
    arr_of_sentences.pop if arr_of_sentences.last.match(/^See/)
  end
  arr_of_sentences.each_slice(2).to_a.map! do |arr|
    {
      definition: arr[0].gsub(/^\d. /, ''),
      examples: arr[1].gsub(/^Examples: /, '')
    }
  end
end

def build_json(verb, verb_page)
  {
    name: verb,
    conjugate: get_conjugate(verb_page),
    definitions: get_definitions(verb_page)
  }.to_json
end

def add_description_to_array(hash_source, arr_destination)
  if hash_source[:link].nil?
    arr_destination << { name: hash_source[:name], error: 'Description not available' }
    return
  end
  verb_page = Nokogiri::HTML(open(hash_source[:link]))
  @progressbar.increment
  arr_destination << build_json(hash_source[:name], verb_page)
end

hashes_with_phrasal_verbs.each do |hash|
  add_description_to_array(hash, @result)
end

File.write('phrasal_verbs.json', @result)
binding.pry
puts "Done, result saved to file: #{Dir.pwd}/phrasal_verbs.json"
