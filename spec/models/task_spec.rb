require 'rails_helper'

RSpec.describe Task, type: :model do
  it { should belong_to(:project) }
  it { should validate_presence_of(:title) }
  it { should define_enum_for(:status).with_values(not_started: 0, in_progress: 1, done: 2) }
end
