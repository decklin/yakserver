require 'yakserver'

Rack::Handler::Mongrel.run YakServer, :Host => 'localhost', :Port => 2562
