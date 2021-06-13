require 'socket'
require 'yaml/store'

birthdays = []

server = TCPServer.new(1337)

store = YAML::Store.new('mirth.yml')
store.transaction do
  unless store[:birthdays]
    store[:birthdays] = []
  end
end

loop do
  client = server.accept

  request_line = client.readline

  puts "The HTTP request line looks line this:"
  puts request_line

  method_token, target, version_number = request_line.split
  case [method_token, target]
  when ["GET", "/show/birthdays"]
    response_status_code = "200 OK"
    content_type = "text/html"
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
        <p><label>Name <input type="text" name="name" /></label></p>
        <p><label>Birthday <input type="date" name="date" /></label></p>
        <p><button>Submit birthday</button></p>
      </form>
    STR

  when ["POST", "/add/birthday"]
    response_status_code = "303 See Other"
    content_type = "text/html"
    response_message = ""

    all_headers = {}
    while true
      line = client.readline
      break if line == "\r\n"
      header_name, value = line.chomp.split(": ")
      all_headers[header_name] = value
    end
    body = client.read(all_headers['Content-Length'].to_i)

    require 'uri'
    new_birthday = URI.decode_www_form(body).to_h

    store.transaction do
      store[:birthdays] << new_birthday.transform_keys(&:to_sym)
    end
  else
    response_status_code = "200 OK"
    content_type = "text/plain"
    response_message = "✅ Received a #{method_token} request to #{target} with #{version_number}"
  end

  puts response_message

  http_response = <<~MSG
    #{version_number} #{response_status_code}
    Content-Type: #{content_type}; charset=#{response_message.encoding.name}
    Location: /show/birthdays

    #{response_message}
  MSG

  client.puts http_response
  client.close
end
