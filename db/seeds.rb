# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
best_case_points = [0, 1, 2, 3]
worst_case_points = [5, 8, 13, 21]

foo_user = User.find_or_create_by(email: "foo@example.com", name: "Foo") { |user|
  user.password = "123456"
}

bar_user = User.find_or_create_by(email: "bar@example.com", name: "bar") { |user|
  user.password = "123456"
}

users = [foo_user, bar_user]

# ============= Start template with subprojects
template = Project.find_or_create_by(title: "Upgrade Templates")

template_projects = [
  {title: "2.3 to 3.0", parent: template},
  {title: "3.0 to 3.1", parent: template},
  {title: "3.2 to 4.0", parent: template}
]
child_one, child_two, child_three = template.projects.create(template_projects)

rand(1..8).times { child_one.stories.create(title: Faker::ChuckNorris.fact) }
rand(1..8).times { child_two.stories.create(title: Faker::ChuckNorris.fact) }
rand(1..8).times { child_three.stories.create(title: Faker::ChuckNorris.fact) }
# ============= End template with subprojects

# ============= Start "hello.io client" project
hello_io = Project.find_or_create_by(title: "Hello.io Client")
child_two.stories.each { |story| hello_io.stories.create(story.dup.attributes) }

hello_io.stories.map do |story|
  estimate = {user: users.sample, best_case_points: best_case_points.sample, worst_case_points: worst_case_points.sample}
  story.estimates.create(estimate)
end
# ============= End "hello.io client" project
