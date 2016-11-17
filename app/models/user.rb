class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_save :generate_second_step_token

  private
  def generate_second_step_token
    self.second_step_token = SecureRandom.uuid unless second_step_token?
  end
end
