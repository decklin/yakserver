# Here it is, the original hair on the yak.

class YakServer

  post '/edit' do
    content_type 'text/plain; charset=utf-8'
    edit_tempfile(request.body.read)
  end

  def edit_tempfile(data)
    temp = Tempfile.new('yakserver')
    temp.write(data)
    temp.close
    fork_editor_and_wait(temp.path)
    read_and_unlink(temp)
  end

  def read_and_unlink(f)
    data = f.open.read
    f.unlink
    data
  end

  def fork_editor_and_wait(*args)
    if fork.nil?
      [STDIN, STDOUT, STDERR].each {|fd| fd.reopen('/dev/null') }
      exec(ENV['EDITOR'], *args)
    else
      Process.wait
    end
  end

end
