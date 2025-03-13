FactoryBot.define do
  factory :project do
    title { 'New Project' }
    description { 'Project Description' }
    association :user
  end
end
