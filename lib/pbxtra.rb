#! /usr/bin/env ruby

require 'uri'
require 'net/https'

module PBXtra
  
# Raised when credentials are incorrect
class LoginError < RuntimeError
end

class UnhandledResponse < RuntimeError
end

class Base
  
  URL  = "/cpa.cgi"
  attr :url, true
  attr :user, false
  attr :pass, false
  attr :connection, true
  attr :debug, true
  attr :cookie, true
  
  def initialize(user, pass, opts={})
    options = { 
      :host   => "https://cp52.fonality.com",
      :debug  => false
    }.merge! opts
    @debug = options[:debug]
    
    @user = user
    @pass = pass
    @host = options[:host]
    @url  = URI.parse(@host + URL)
    
    # Handles http/https in url string
    @ssl  = false
    @ssl  = true if @url.scheme == "https"
    
    @connection = false
    login!
    raise LoginError, "Invalid Username or Password" unless logged_in?
  end
  
  def get(method, parameters={})
    @url.query = wrap_url_query(method, parameters)
    request(Net::HTTP::Get.new(@url.path + @url.query, header)).body
  end
  
  def post(method=nil, parameters={}, body={})
    @url.query = wrap_url_query(method, parameters)
    req = Net::HTTP::Post.new(@url.path + @url.query, header)
    req.body = wrap_body(body)
    request(req)
  end
  
  # Send a request to the CP.  Send Auth information if we have it.
  def request(request)
    login! unless logged_in?
    if @debug
      puts "Request Type: #{request.class}"
      puts "Request Path: #{@url}"
      puts "Request Body: #{request.body}"
      puts "\n"
    end
    response = @connection.request(request)
    if @debug
      puts "Response Header: " + response.header.to_s
      puts "Response Body: " + response.body 
      puts "\n"
    end
    case response
      when Net::HTTPOK
        return response
      when Net::HTTPUnauthorized
        login!
        request(method, parameters)
      when Net::HTTPForbidden
        raise LoginError, "Invalid Username or Password" 
      else 
        raise UnhandledResponse, "Can't handle response #{response}"
    end
  end

  protected
  
    # Attempt authentication with PBXtra CP
    def login!
      connect! unless connected?
      body = {
        :forcesec => nil,
        :do       => 'authenticate',
        :username => @user,
        :password => @pass
      }
      request  = Net::HTTP::Post.new(@url.path)
      request.body = wrap_body(body)
      response = @connection.request(request)
      
      if response["Set-Cookie"]
        @cookie  = response["Set-Cookie"].split(/;/)[0]
      else
        raise LoginError, "Invalid Username or Password"
      end
      
      if @debug
        puts "Cookie: #{@cookie}"
      end

    end
  
    # Check to see if we are logged in
    def logged_in?
      return false unless @cookie
      true
    end
    
    # Check to see if we have an HTTP/S Connection
    def connected?
      return false unless @connection
      return false unless @connection.started?
      true
    end

    # Connect to the remote system.
    def connect!
      @connection = Net::HTTP.new(@url.host, @url.port)
      if @ssl
        @connection.use_ssl = true
        @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      @connection.start
    end
    
    def wrap_url_query(method, parameters={})
      url = "?do=#{method}"
      parameters.each_pair do |k,v|
        url << "&" + k.to_s + "=" + v.to_s
      end
      url
    end
    
    def wrap_body(parameters={})
      body = []
      parameters.each_pair do |k,v|
        body << k.to_s + "=" + v.to_s
      end
      body.join('&')
    end
    
    def header
      if @cookie
        {'Cookie' => @cookie, 'Accept-Encoding' => ''}
      else
        {}
      end
    end
  
end 

end
