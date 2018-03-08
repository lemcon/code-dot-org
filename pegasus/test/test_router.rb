require_relative './test_helper'
require_relative '../router'
require 'helpers/auth_helpers'
require 'cdo/rack/request'
require 'parallel'

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
    DB.disconnect
    all_documents = app.helpers.all_documents.reject do |page|
      page[:uri].end_with?('/splat')
    end
    rendered_map = Parallel.map(all_documents) do |page|
      site = page[:site]
      uri = page[:uri]
      header 'host', site
      resp = get uri
      {url: "#{site}#{uri}", status: resp.status}
    end

    # All pages are expected to return 200 with the following exceptions:
    exceptions = {
      302 => %w[
        code.org/educate
        code.org/teacher-dashboard
        code.org/teacher-dashboard/review-hociyskvuwa
        code.org/teach code.org/student
      ],
      301 => %w[
        csedweek.org/resource_kit
      ],
      401 => %w[
        code.org/create-company-profile
      ]
    }
    rendered_map.each do |page|
      url = page[:url]
      status = page[:status]
      unless status == 200
        assert_includes exceptions[status], url, "#{url} returned invalid status #{status}"
      end
    end
  end
end
