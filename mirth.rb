require 'socket'

server = TCPServer.new(1337)
loop do
  client = server.accept

  request_line = client.readline

  puts "The HTTP request line looks line this:"
  puts request_line

  method_token, target, version_number = request_line.split
  response_body = "Received a #{method_token} request to #{target} with #{version_number}"
  client.puts <<~MSG
    #{version_number} 200 OK
    Content-Type: text/plain

    #{response_body}
  MSG
  client.close
end
