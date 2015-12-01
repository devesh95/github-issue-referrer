class CreateIssues < ActiveRecord::Migration
  def change
    create_table :issues do |t|
      t.string :url
      t.string :title
      t.string :body
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end
  end
end
