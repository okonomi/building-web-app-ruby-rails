require 'socket'

server = TCPServer.new(1337)
loop do
  client = server.accept

  request_line = client.readline

  puts "The HTTP request line looks line this:"
  puts request_line

  method_token, target, version_number = request_line.split
  case [method_token, target]
  when ["GET", "/show/birthdays"]
    response_status_code = "200 OK"
    content_type = "text/plain"
    response_message = "show birthdays"
  when ["POST", "/add/birthday"]
    response_status_code = "201 Created"
    content_type = "text/plain"
    response_message = "add birthday"
  else
    response_status_code = "200 OK"
    content_type = "text/plain"
    response_message = "Received a #{method_token} request to #{target} with #{version_number}"
  end

  client.puts <<~MSG
    #{version_number} #{response_status_code}
    Content-Type: #{content_type}

    #{response_message}
  MSG
  client.close
end
