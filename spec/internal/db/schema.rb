ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :username
    t.timestamps null: false
  end

  create_table :posts, force: true do |t|
    t.string :name
    t.belongs_to :user, foreign_key: true
    t.timestamps null: false
  end
end
