require 'pry'
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'ruby-progressbar'

URI_BASE = 'https://www.skypeenglishclasses.com/english-phrasal-verbs/'.freeze

page = Nokogiri::HTML(open(URI_BASE))

list_of_phrasal_verbs = page.css('#content div.content-text table tbody tr')
                            .map { |i| i.css('td a').text }

# removing title of the table
list_of_phrasal_verbs.shift

total_verbs = list_of_phrasal_verbs.length

threads = []

@result = []

@progressbar = ProgressBar.create(format: '%a |%b>>%i| %p%% %t', total: total_verbs)

def make_uri_fragment(verb)
  URI::encode(verb.gsub(' ', '-'))
end

def get_conjugate(page)
  page.css('main div div div ul').children.select(&:element?).map(&:text)
end

def get_definitions(page)
  arr_of_sentences = page.css('main div div div div p').map(&:text)
  arr_of_sentences.pop if arr_of_sentences.last.match(/^See/)
  arr_of_sentences.each_slice(2).to_a.map! do |arr|
    {
      definition: arr[0].gsub(/^\d. /, ''),
      examples: arr[1].gsub(/^Examples: /, '')
    }
  end
end

def add_description_to_array(arr_source, arr_destination)
  arr_source.each_with_object(arr_destination) do |verb, arr|
    begin
      verb_page = Nokogiri::HTML(open("#{URI_BASE + make_uri_fragment(verb)}"))
      json = {
        name: verb,
        conjugate: get_conjugate(verb_page),
        definitions: get_definitions(verb_page)
      }.to_json
    rescue OpenURI::HTTPError
      json = { error: 'Description not available' }.to_json
#    rescue NoMethodError => e
      #puts e
      #puts "#{URI_BASE + make_uri_fragment(verb)}"
    end
    @progressbar.increment
    arr << json
  end
end

binding.pry
# for these case instead of using concurrent gem i've decided to create safty threads
# by pushing unique lists of verbs into each thread
list_of_phrasal_verbs.each_slice(total_verbs/10).each_with_object(threads) do |arr, thr|
  thr << Thread.new { add_description_to_array(arr, @result) }
end.each(&:join)

File.write('phrasal_verbs.json', @result)

puts "Done, result saved to file: #{Dir.pwd}/phrasal_verbs.json"
