class ApplicationController < ActionController::API
  include Authenticatable
  include Paginatable
end
