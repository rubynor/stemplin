class DropMembershipsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :memberships
  end
end
