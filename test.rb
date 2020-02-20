# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'parser'

class Parser < Minitest::Test
  parallelize_me!

  def setup
    @verbs_list = get_phrasal_verbs(URI_BASE)
    @sample_verb = 'Throw Out'
    @sample_page = Nokogiri::HTML(open('https://www.skypeenglishclasses.com/english-phrasal-verbs/throw-out/'))
  end

  def test_verb_list_containing_390_hashes
    assert_equal @verbs_list.length, 390
    assert @verbs_list.all?(Hash)
  end

  def test_each_hash_contain_verb_name_in_list
    refute @verbs_list.all? { |i| i[:name].empty? }
    assert @verbs_list.all? { |i| i[:name].is_a?(String) }
  end

  def test_get_conjuaget_return_valid_values
    result = get_conjugate(@sample_page)
    assert result[0].match(/^Infinitive:/)
    assert result[1].match(/^Present Tense:/)
    assert result[2].match(/^-ing Form:/)
    assert result[3].match(/^Past Tense:/)
    assert result[4].match(/^Past Participle:/)
  end

  def test_get_definitions_return_valid_values
    result = get_definitions(@sample_page)
    assert_equal result.length, 2
    assert_match /^When you get rid of/, result[0][:definition]
    assert_match /^When you forcefully/, result[1][:definition]
    assert_match /books when she moved(.)$/, result[0][:examples]
    assert_match /out just as we arrived(.)$/, result[1][:examples]
  end

  def test_build_json_return_valid_json
    response = build_json(@sample_verb, @sample_page)
    json = JSON.parse(response)
    assert_equal json.dig('name'), @sample_verb
    assert_equal json.dig('conjugate'), get_conjugate(@sample_page)
    assert_equal json.dig('definitions'), JSON.parse(get_definitions(@sample_page).to_json)
  end

  def test_add_description_to_source_array_valid_behavior
    @progressbar = ProgressBar.create
    arr_destination = []
    hash_verb = { name: @sample_verb, link: 'https://www.skypeenglishclasses.com/english-phrasal-verbs/throw-out/' }
    add_description_to_source_array(hash_verb, arr_destination)

    assert_equal arr_destination.length, 1
    assert_instance_of String, arr_destination.first
  end
end
