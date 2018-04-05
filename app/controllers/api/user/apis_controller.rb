require 'user/api'

class Api::User::ApisController < ApiController

  # GET /api/api_users
  def index
    @apis = policy_scope(User::Api)
    render_json @apis
  end

  # GET /api/api_users/1
  def show
    authorize api
    render_json api
  end

  # POST /api/api_users
  def create
    new_api = current_user.api_users.new(permitted_attributes(User::Api))
    authorize new_api
    new_api.save!
  end

  # POST /api/api_users/1
  def update
    authorize api
    api.update!(permitted_attributes(api))
  end

  # DELETE /api/api_users/1
  def destroy
    authorize api
    api.destroy!
  end

  private

  def api
    @api ||= User::Api.find(params[:id])
  end

  def password
    params[:user_api][:password]
  end
end