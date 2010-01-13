# Some simple examples demonstrating how to write a YakServer module.
# For background on how `get` and `post` work, refer to the Sinatra
# docs.
#
# These trivial responses work fine as HTML, but if you actually
# wanted to serve a chunk of text, you should use the `content_type`
# helper.

class YakServer

  # A familiar greeting.

  get '/hello' do
    "Hello, world!\n"
  end

  # Do something with side effects. Because this is a POST route, it
  # always requires authentication. Note that this form of
  # Kernel#system does not use the shell to interpret arguments. Do
  # **not** use the one that does. You are not smarter than the shell.

  post '/sayhi' do
    message = params[:message] || "Hi."
    system 'say', message
  end

  # This is a GET route, but we want authentication on it anyway.

  get '/handshake' do
    require_auth!
    "Shh! It's a secret.\n"
  end

end
