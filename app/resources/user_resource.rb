class UserResource
  include Alba::Resource

  attribute :guest_expires_at, if: proc { |_user, params| params[:type] == :guest }

  attribute :email, if: proc { |_user, params| params[:type] == :google }
  attribute :name, if: proc { |_user, params| params[:type] == :google }
  attribute :avatar_url, if: proc { |_user, params| params[:type] == :google }
end
