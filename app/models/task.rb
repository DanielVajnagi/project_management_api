class Task < ApplicationRecord
  belongs_to :project
  validates :title, presence: true
  enum :status, { not_started: 0, in_progress: 1, done: 2 }
end
