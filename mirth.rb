require 'yaml/store'

require 'rack'
require 'rack/handler/puma'

app = -> environment do
  request = Rack::Request.new(environment)

  store = YAML::Store.new('mirth.yml')
  store.transaction do
    unless store[:birthdays]
      store[:birthdays] = []
    end
  end

  if request.get? && request.path == '/show/birthdays'
    status = 200
    content_type = 'text/html'
    response_message = "<ul>\n"

    all_birthdays = []
    store.transaction do
      all_birthdays = store[:birthdays]
    end

    all_birthdays.each do |birthday|
      response_message << "<li> <b>#{birthday[:name]}</b> was born on #{birthday[:date]}!</li>\n"
    end
    response_message << "</ul>\n"
    response_message << <<~STR
      <form action="/add/birthday" method="post">
        <p><label>Name <input type="text" name="name" required /></label></p>
        <p><label>Birthday <input type="date" name="date" required /></label></p>
        <p><button>Submit birthday</button></p>
      </form>
    STR
  elsif request.post? && request.path == '/add/birthday'
    status = 303
    content_type = 'text/html'
    response_message = ''

    new_birthday = request.params

    store.transaction do
      store[:birthdays] << new_birthday.transform_keys(&:to_sym)
    end
  else
    status = 200
    content_type = 'text/plain'
    response_message = "✅ Received a #{request.request_method} request to #{request.path}"
  end

  headers = {
    'Content-Type' => "#{content_type}; charset=#{response_message.encoding.name}",
    'Location' => '/show/birthdays'
  }
  body = [response_message]

  [status, headers, body]
end

Rack::Handler::Puma.run(app, Port: 1337, Verbose: true)
