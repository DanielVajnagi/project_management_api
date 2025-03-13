FactoryBot.define do
  factory :task do
    title { "Test Task" }
    description { "Task description" }
    status { :not_started }
    association :project
  end
end
