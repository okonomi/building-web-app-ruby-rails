require 'rack'
require 'rack/handler/puma'

require 'sqlite3'

app = -> environment do
  request = Rack::Request.new(environment)
  response = Rack::Response.new

  database = SQLite3::Database.new 'mirth.sqlite3', results_as_hash: true

  if request.get? && request.path == '/show/birthdays'
    response.status = 200
    response.content_type = 'text/html; charset=UTF-8'
    response.write "<ul>\n"

    all_birthdays = database.execute('SELECT * FROM birthdays')

    all_birthdays.each do |birthday|
      response.write "<li> <b>#{birthday['name']}</b> was born on #{birthday['date']}!</li>\n"
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

    query = 'INSERT INTO birthdays (name, date) VALUES (?, ?)'
    database.execute query, [new_birthday['name'], new_birthday['date']]

    response.redirect '/show/birthdays', 303
  else
    response.status = 200
    response.content_type = 'text/plain; charset=UTF-8'
    response.write "✅ Received a #{request.request_method} request to #{request.path}"
  end

  response.finish
end

Rack::Handler::Puma.run(app, Port: 1337, Verbose: true)
