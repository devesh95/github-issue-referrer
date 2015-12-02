class AddColumnsToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :referrer, :string
    add_column :issues, :repo, :string
    add_column :issues, :notes, :string
    add_column :issues, :number, :integer
  end
end
