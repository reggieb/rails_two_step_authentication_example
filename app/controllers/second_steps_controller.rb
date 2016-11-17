class SecondStepsController < ApplicationController
  before_action :authenticate_user!

  def new
    session[:second_step_token] = nil
  end

  def create
    if params[:foo] == 'Foo'
      session[:second_step_token] = current_user.second_step_token
      redirect_to root_path, notice: 'Second authentication step completed'
    else
      flash[:alert] = "That wasn't 'Foo'"
      render :new
    end
  end
end
