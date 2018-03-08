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

  def test_markdown
    path = '/challenge'
    resp = get(path)
    assert_equal 200, resp.status, path
    assert_match '<div class="col-50">', resp.body
  end
end
