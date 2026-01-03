# frozen_string_literal: true
class AddEmailEchoEnabledUserOption < ActiveRecord::Migration[7.2]
  def change
    add_column :user_options, :email_echo_enabled, :boolean, null: false, default: false
  end
end
