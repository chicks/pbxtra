#! /usr/bin/env ruby

require 'uri'
require 'net/https'

module PBXtra
  
# Raised when credentials are incorrect
class LoginError < RuntimeError
end

class Base
  
  HOST = "cp-b.fonality.com"
  URL  = "/cpa.cgi"
  attr :url, true
  attr :user, false
  attr :pass, false
  attr :connection, true
  attr :debug, true
  attr :cookie, true
  
  def initialize(user, pass, options={})
    {:debug => false}.merge! options
    @debug = options[:debug]
    
    @user = user
    @pass = pass
    @url  = URI.parse("https://" + HOST + URL)
    
    # Handles http/https in url string
    @ssl  = false
    @ssl  = true if @url.scheme == "https"
    
    @connection = false
    login!
    raise LoginError, "Invalid Username or Password" unless logged_in?
  end
  
  # Send a request to the CP.  Send Auth information if we have it.
  def request(method, parameters={})
    login! unless logged_in?
    
    # Sanitize and wrap our method + paramters
    query = wrap(method, parameters) 
    @url.query = query
    
    # Send the request
    header   = {'Cookie' => @cookie, 'Accept-Encoding' => ''}
    request  = Net::HTTP::Get.new(@url.path + @url.query, header)
    response = @connection.request(request)

    if @debug
      puts "Path: #{@url.path}"
      puts response
      puts "\n"
    end

    case response
      when Net::HTTPOK
        raise EmptyResponse unless response.body
        return response.body
      when Net::HTTPUnauthorized
        login!
        request(method, parameters)
      when Net::HTTPForbidden
        raise LoginError, "Invalid Username or Password" 
      else raise UnhandledResponse, "Can't handle response #{response}"
    end
  end

  protected
  
    # Attempt authentication with PBXtra CP
    def login!
      connect! unless connected?
      request  = Net::HTTP::Post.new(@url.path)
      request.body = "forcesec=&do=authenticate&username=#{@user}&password=#{@pass}"
      response = @connection.request(request)
      @cookie  = response["Set-Cookie"].split(/;/)[0]
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
    
    def wrap(method, parameters)
      body = "?do=#{method}"
      parameters.each_pair do |k,v|
        body << "&" + k.to_s + "=" + v.to_s
      end
      body
    end
  
end 

end
