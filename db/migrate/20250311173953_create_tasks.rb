class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :status, default: 0, null: false
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
