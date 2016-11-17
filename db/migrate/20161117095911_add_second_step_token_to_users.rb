class AddSecondStepTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :second_step_token, :string
  end
end
