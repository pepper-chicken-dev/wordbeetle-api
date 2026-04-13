class UserResource
  include Alba::Resource

  attribute :guest_expires_at, if: proc { |_user| params[:type] == :guest }, &:guest_expires_at

  attribute :email, if: proc { |_user| params[:type] == :google }, &:email
  attribute :name, if: proc { |_user| params[:type] == :google }, &:name
  attribute :avatar_url, if: proc { |_user| params[:type] == :google }, &:avatar_url
end
