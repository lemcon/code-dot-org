require_relative './test_helper'
require_relative '../router'
require 'helpers/auth_helpers'
require 'cdo/rack/request'

class TestDocuments < Documents
  configure do
    set :views, File.join(__dir__, 'fixtures/sites')
  end
end

class RouterTest < Minitest::Test
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

  def test_all_documents
    assert_includes app.helpers.all_documents, '/div_brackets'
  end
end

class PegasusTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Documents.new
  end

  def test_pegasus
    documents = Documents.new.helpers.all_documents.map do |page|
      "#{page[:site]}#{page[:uri]}"
    end
    puts documents
  end

  def test_render_pegasus_documents
    app.helpers.all_documents.each do |page|
      site = page[:site]
      uri = page[:uri]
      next if uri.end_with?('/splat')
      print "#{site}#{uri}: "
      header 'host', site
      resp = get uri
      puts resp.status
    end
  end
end
