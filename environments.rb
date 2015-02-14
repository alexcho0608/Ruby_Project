require 'active_record'

configure :development do
ActiveRecord::Base.establish_connection(:adapter => "sqlite3",:database  => "E:/Ruby_Project/site3.db")
=begin
ActiveRecord::Schema.define do
  create_table :Users do |table|
    table.column :username, :string
    table.column :password, :string
    table.column :email, :string
    table.column :role, :string
    table.column :status, :integer
  end
  create_table :Messages do |table|
    table.column :image_id, :integer
    table.column :user_name, :string
    table.column :content, :string
    table.column :date, :string
  end
  create_table :Photos do |table|
    table.column :user_id, :integer
    table.column :format, :string
    table.column :name, :string
  end
  create_table :Friends do |table|
    table.column :first_id, :integer
    table.column :second_id, :integer
    table.column :status, :integer
  end
  create_table :Requests do |table|
    table.column :username_from, :string
    table.column :username_to, :string
    table.column :status, :integer
  end
end
=end
end