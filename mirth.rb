require 'yaml/store'

require 'rack'
require 'rack/handler/puma'

app = -> environment do
  request = Rack::Request.new(environment)
  response = Rack::Response.new

  store = YAML::Store.new('mirth.yml')
  store.transaction do
    unless store[:birthdays]
      store[:birthdays] = []
    end
  end

  if request.get? && request.path == '/show/birthdays'
    response.status = 200
    response.content_type = 'text/html'
    response.write "<ul>\n"

    all_birthdays = []
    store.transaction do
      all_birthdays = store[:birthdays]
    end

    all_birthdays.each do |birthday|
      response.write "<li> <b>#{birthday[:name]}</b> was born on #{birthday[:date]}!</li>\n"
    end
    response.write "</ul>\n"
    response.write <<~STR
      <form action="/add/birthday" method="post">
        <p><label>Name <input type="text" name="name" required /></label></p>
        <p><label>Birthday <input type="date" name="date" required /></label></p>
        <p><button>Submit birthday</button></p>
      </form>
    STR
  elsif request.post? && request.path == '/add/birthday'
    new_birthday = request.params
    store.transaction do
      store[:birthdays] << new_birthday.transform_keys(&:to_sym)
    end

    response.redirect '/show/birthdays', 303
  else
    response.status = 200
    response.content_type = 'text/plain; charset=UTF-8'
    response.write "✅ Received a #{request.request_method} request to #{request.path}"
  end

  response.finish
end

Rack::Handler::Puma.run(app, Port: 1337, Verbose: true)
