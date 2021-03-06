# frozen_string_literal: true

require 'net/http'
require 'json'
require 'time'

@GITHUB_SHA = ENV['GITHUB_SHA']
@GITHUB_EVENT_PATH = ENV['GITHUB_EVENT_PATH']
@GITHUB_TOKEN = ENV['GITHUB_TOKEN']
@GITHUB_WORKSPACE = ENV['GITHUB_WORKSPACE']

@event = JSON.parse(File.read(ENV['GITHUB_EVENT_PATH']))
@repository = @event['repository']
@owner = @repository['owner']['login']
@repo = @repository['name']

@check_name = 'Rubocop'

@headers = {
  "Content-Type" => 'application/json',
  "User-Agent" => 'rankmi-rubocop-lintern',
  "Accept" => 'application/vnd.github.antiope-preview+json',
  "Authorization" => "Bearer #{@GITHUB_TOKEN}"
}

@annotation_levels = {
  'refactor' => 'failure',
  'convention' => 'failure',
  'warning' => 'warning',
  'error' => 'failure',
  'fatal' => 'failure'
}

def create_check
  body = {
    'name' => @check_name,
    'head_sha' => @GITHUB_SHA,
    'status' => 'in_progress',
    'started_at' => Time.now.iso8601
  }

  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs"
  resp = http.post(path, body.to_json, @headers)
  raise resp.message if resp.code.to_i > 299
  data = JSON.parse(resp.body)
  data['id']
end

def update_check(id, conclusion, output)
  body = {
    'name' => @check_name,
    'head_sha' => @GITHUB_SHA,
    'status' => 'completed',
    'completed_at' => Time.now.iso8601,
    'conclusion' => conclusion,
    'output' => output
  }

  http = Net::HTTP.new('api.github.com', 443)
  http.use_ssl = true
  path = "/repos/#{@owner}/#{@repo}/check-runs/#{id}"

  resp = http.patch(path, body.to_json, @headers)
  raise resp.message if resp.code.to_i >= 300
end


def run_rubocop
  annotations = []
  errors = nil
  Dir.chdir(@GITHUB_WORKSPACE) do
    errors = JSON.parse(`bundle exec rubocop --format json`)
  end
  conclusion = 'success'
  count = 0

  errors['files'].each do |file|
    path = file['path']
    offenses = file['offenses']

    offenses.each do |offense|
      severity = offense['severity']
      message = offense['message']
      location = offense['location']
      annotation_level = @annotation_levels[severity]
      count += 1

      conclusion = 'failure' if annotation_level.eql?('failure')

      annotations.push(
        'path' => path,
        'start_line' => location['start_line'],
        'end_line' => location['start_line'],
        "annotation_level": annotation_level,
        'message' => message
      )
    end
  end

  output = {
    "title" => @check_name,
    "summary" => "#{count} issues  found",
    'annotations' => annotations
  }
  { 'output' => output, 'conclusion' => conclusion }
end

def run
  id = create_check
  results = run_rubocop
  conclusion = results['conclusion']
  output = results['output']

  update_check(id, conclusion, output)

  if conclusion.eql?('failure')
    puts output[:summary]
    output[:annotations].each do |annotation|
      puts "L#{annotation[start_line]}-L#{annotation[end_line]}:#{annotation[message]}"
    end
    raise 'Rubocop found some issues :( '
  end
rescue StandardError
  update_check(id, 'failure', nil)
  raise
end

run
