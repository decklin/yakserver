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
    system ENV['EDITOR'], temp.path
    read_and_unlink(temp)
  end

  def read_and_unlink(f)
    data = f.open.read
    f.unlink
    data
  end

end
