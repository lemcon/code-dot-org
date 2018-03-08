require_relative './test_helper'
require_relative '../router'
require 'helpers/auth_helpers'
require 'cdo/rack/request'

class TestDocuments < Documents
  configure do
    set :views, File.join(__dir__, 'fixtures')
  end
end

class HamlTest < Minitest::Test
  include Rack::Test::Methods

  def app
    TestDocuments.new
  end

  def test_div_brackets
    path = '/div_brackets'
    resp = get(path)
    assert_equal 200, resp.status, path
    assert_match '<div class="class">', resp.body
    assert_match '<div id="id">', resp.body
  end
end
