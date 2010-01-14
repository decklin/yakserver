#!/usr/bin/ruby

# Installing Sinatra via apt-get does not pull in rubygems, but everything
# still works. If you're using rubygems but didn't install Sinatra, you'll
# just see the LoadError for sinatra/base on the next line.

begin
  require 'rubygems'
rescue LoadError
end

require 'sinatra/base'
require 'fcntl'

# Writing this as a Sinatra::Base subclass so we can also use rackup. See
# below for the magic that makes it run.

class YakServer < Sinatra::Base

  configure do
    home_dir = "#{ENV['HOME']}/.yakserver"
    port_path = "#{home_dir}/port"
    creds_path = "#{home_dir}/credentials"
    static_dir = "#{home_dir}/public"
    mods_dir = "#{home_dir}/modules"

    begin
      if File.stat(creds_path).mode & 077 != 0
        STDERR.puts "Warning: credentials file readable by other users."
        STDERR.puts "Please ``chmod 600 #{creds_path}''."
      end
    rescue
      STDERR.puts "Error: no credentials. Clients will be unable to auth."
      STDERR.puts "Please ``echo username:password > #{creds_path}''."
      exit 1
    end

    creds = File.open(creds_path).read.strip.split(':') rescue nil
    port = File.open(port_path).read.to_i rescue 2562

    enable :static

    set :host, 'localhost'
    set :port, port
    set :public, static_dir
    set :credentials, creds
    set :home, home_dir

    [File.dirname(__FILE__)+"/modules", mods_dir].each do |d|
      dir = Dir.new(d) rescue next
      dir.each {|p| load "#{d}/#{p}" unless p == '.' || p == '..' }
    end

    [STDIN, STDOUT, STDERR].each do |f|
      f.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
    end
  end

  helpers do
    def require_auth!
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      unless @auth.provided? && @auth.basic? &&
             @auth.credentials == options.credentials
        response['WWW-Authenticate'] = 'Basic'
        throw :halt, [401, "Not authorized\n"]
      end
    end
  end

  before do
    # Enforce access policy
    unless request.request_method == 'GET' || request.request_method == 'HEAD'
      require_auth!
    end
  end

  # This is a kinda lame index page, because you probably already had to
  # look at the README to get this far, but it's better than nothing.

  get '/' do
    content_type 'text/plain'
    File.open(File.dirname(__FILE__)+'/README').read
  end

end

# So, if it was this script that was invoked from the shell, start the
# server. If not, assume something like rackup is taking care of it.

YakServer.run! if $0 == __FILE__
