require 'uri'

class YakServer

  get '/style/get' do
    content_type 'text/css'
    UserStyle.new("#{options.home}/userstyles", params[:url]).get
  end

  post '/style/edit' do
    UserStyle.new("#{options.home}/userstyles", params[:url]).edit
  end

end

class UserStyle

  def initialize(base, url)
    @base = base
    @uri = URI.parse(url.gsub(/[\x80-\xff]/) {|m| '%%%02x'%m[0] }) rescue nil
  end

  def css_paths
    ret = ['__all__']
    if @uri
      hosts do |h|
        ret << h
        paths do |p|
          ret << h + p
        end
      end
    end
    ret
  end

  def hosts
    if @uri.host
      parts = @uri.host.split('.')
      [parts.length-2, 0].max.downto(0).each do |i|
        if i == 0 or parts.drop(i).any? {|p| p.length > 2 }
          yield parts.drop(i).join('.')
        end
      end
    end
  end

  def paths
    if @uri.path
      parts = @uri.path.split('/')
      2.upto(parts.length).each do |i|
        yield parts.take(i).join('/')
      end
    end
  end

  def local(path)
    "#{@base}/#{path}.css"
  end

  def get
    css_paths.collect do |p|
      begin
        "/* #{p}.css */\n\n" + File.open(local(p)).read
      rescue
        "/* no #{p}.css */\n"
      end
    end.join("\n")
  end

  def edit
    lpaths = css_paths.collect {|p| local(p)}.select {|p| File.exists? p}
    exec ENV['EDITOR'], *lpaths if fork.nil?
  end

end
