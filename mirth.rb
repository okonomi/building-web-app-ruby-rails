require 'rack'
require 'rack/handler/puma'

require 'sqlite3'

require 'action_controller'
require 'action_dispatch'
require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'mirth.sqlite3')

class Birthday < ActiveRecord::Base
end

ActionController::Base.prepend_view_path('.')

class BirthdaysController < ActionController::Base
  def index
    @birthdays = Birthday.all
  end

  def create
    Birthday.create!(name: params['name'], date: params['date'])
    redirect_to action: :index
  end
end

router = ActionDispatch::Routing::RouteSet.new
BirthdaysController.include(router.url_helpers)

router.draw do
  resources :birthdays
end

Rack::Handler::Puma.run(router, Port: 1337, Verbose: true)
