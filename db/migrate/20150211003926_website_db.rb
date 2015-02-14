class WebsiteDb < ActiveRecord::Migration
  def change
  end
    def up
    create_table :Users do |table|
        table.string :username
        table.string :password
        table.string :email
        table.string :role
    end
    create_table :Messages do |table|
        table.integer :image_id
        table.string :username
        table.string :content
        table.timestamps
    end
    create_table :Image do |table|
        table.integer :user_id
        table.integer :format
        table.string :name
    end
    create_table :Friends do |table|
        table.integer :first_id
        table.integer :second_id
        table.integer :status
    end
    create_table :Requests do |table|
        table.string :username_from
        table.string :username_to
        table.integer :status
    end
  end
  def down
  	drop_table :Users
  	drop_table :Messages
  	drop_table :Image
  	drop_table :Friends
  	drop_table :Requests
  end
end
