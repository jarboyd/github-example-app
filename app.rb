require "sinatra"
require "dotenv/load"
require "net/http"
require "json"

CLIENT_ID = ENV.fetch("CLIENT_ID")
CLIENT_SECRET =ENV.fetch("CLIENT_SECRET")

def parse_response(response)
  case response
  when Net::HTTPOK
    JSON.parse(response.body)
  else
    puts response
    puts response.body
    {}
  end
end

def exchange_code(code)
  params = {
    "client_id" => CLIENT_ID,
    "client_secret" => CLIENT_SECRET,
    "code" => code
  }
  result = Net::HTTP.post(
    URI("https://github.com/login/oauth/access_token"),
    URI.encode_www_form(params),
    {"Accept" => "application/json"}
  )

  parse_response(result)
end

def user_info(token)
  uri = URI("https://api.github.com/user")

  result = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    body = {"access_token" => token}.to_json

    auth = "Bearer #{token}"
    headers = {"Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => auth}

    http.send_request("GET", uri.path, body, headers)
  end

  parse_response(result)
end

get "/" do
  link = '<a href="https://github.com/login/oauth/authorize?client_id=<%= CLIENT_ID %>">Login with GitHub</a>'
  erb link
end

get "/github/callback" do
  code = params["code"]

  token_data = exchange_code(code)

  if token_data.key?("access_token")
    token = token_data["access_token"]

    user_info = user_info(token)
    handle = user_info["login"]
    name = user_info["name"]

    render = "Sucessfully authorized! Welcome, #{name} (#{handle}). Example search: #{example_search}."
    erb render
  else
    render = "Authorized, but unable to exchange code #{code} for token."
    erb render
  end
end


