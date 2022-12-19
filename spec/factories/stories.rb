FactoryBot.define do
  factory :story do
    title { Faker::ChuckNorris.fact }
    description { Faker::Marketing.buzzwords }
    real_score { 2 }
    project
  end
end
