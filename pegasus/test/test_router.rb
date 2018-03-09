require_relative './test_helper'
require_relative '../router'
require 'helpers/auth_helpers'
require 'cdo/rack/request'
require 'parallel'
require 'open3'

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
    assert_match "<div class='class'>", resp.body
    assert_match "<div id='id'>", resp.body
  end

  def test_all_documents
    assert_includes app.helpers.all_documents, {site: 'code.org', uri: '/div_brackets'}
  end
end

class PegasusTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Documents.new
  end

  def test_pegasus_documents
    documents = Documents.new.helpers.all_documents.map do |page|
      "#{page[:site]}#{page[:uri]}"
    end
    CDO.log.info "Found #{documents.length} Pegasus documents."
    assert_operator documents.length, :>, 2000
  end

  # All pages should return 200 status-code, with the following exceptions:
  STATUS_EXCEPTIONS = {
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
  # All pages expected to return 'text/html' content-type, with the following exceptions:
  CONTENT_EXCEPTIONS = {
    'text/plain' => %w[
      code.org/health_check
      code.org/robots.txt
    ],
    'text/ng-template' => %w[
      code.org/teacher-dashboard/section_projects
      code.org/teacher-dashboard/section_stats
      code.org/teacher-dashboard/section
      code.org/teacher-dashboard/section_progress
      code.org/teacher-dashboard/sections
      code.org/teacher-dashboard/section_assessments
      code.org/teacher-dashboard/nav
      code.org/teacher-dashboard/landing
      code.org/teacher-dashboard/plan
      code.org/teacher-dashboard/student
      code.org/teacher-dashboard/section_responses
      code.org/teacher-dashboard/signin_cards
      code.org/teacher-dashboard/section_manage
    ]
  }

  def test_render_pegasus_documents
    all_documents = app.helpers.all_documents.reject do |page|
      page[:uri].end_with?('/splat')
    end
    DB.disconnect
    DASHBOARD_DB.disconnect
    errors = Parallel.map(all_documents) do |page|
      site = page[:site]
      uri = page[:uri]
      url = "#{site}#{uri}"
      header 'host', site
      response = get(uri)
      status = response.status

      if status == 200
        content_type = response.headers['Content-Type'].split(';', 2).first.downcase
        if content_type == 'text/html'
          # Ensure HTML is valid.
          status, result = validate(response.body)
          if status == 2
            errors = result.lines.select {|line| line =~ /Error:/}.join
            next "[#{url}] HTML validation failed:\n#{errors}"
          end
        else
          exceptions = CONTENT_EXCEPTIONS[content_type] || []
          next "[#{url}] returned invalid Content-Type #{content_type}" unless exceptions.include?(url)
        end
      else
        exceptions = STATUS_EXCEPTIONS[status] || []
        next "[#{url}] returned invalid status #{status}" unless exceptions.include?(url)
      end
      nil
    end.compact

    assert_equal 0, errors.length, "Page rendering errors:\n#{errors.join("\n")}"
  end

  # Runs `tidy` in a subprocess to validate HTML content.
  # Status codes:
  # 0 on successful validation
  # 1 if warnings are present
  # 2 if errors are present
  def validate(body)
    cmd = 'tidy -q -e'
    status, result = nil
    Open3.popen3(cmd) do |stdin, _stdout, stderr, wait_thread|
      stdin.puts body
      stdin.close
      result = stderr.read
      status = wait_thread.value.exitstatus
    end
    [status, result]
  end
end
