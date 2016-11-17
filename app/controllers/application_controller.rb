class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def authenticate_user_with_second_step!
    authenticate_user!
    authentication_second_step!
  end

  def authentication_second_step!
    authenticate_user! unless user_signed_in?
    return true if current_user.second_step_token == session[:second_step_token]
    redirect_to new_second_step_path
  end
end
