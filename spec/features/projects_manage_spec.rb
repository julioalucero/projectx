require "rails_helper"

RSpec.describe "managing projects", js: true do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }

  before do
    login_as(user, scope: :user)
  end

  it "allows me to sign in" do
    visit root_path
    expect(page).to have_content "Sign out"
  end

  it "allows me to add a project" do
    visit root_path
    click_link "Add a Project"
    fill_in "project[title]", with: "Super Project"
    click_button "Create"
    expect(Project.count).to eq 1
  end

  it "allows me to delete a project", js: false do
    visit project_path(id: project.id)
    click_link "Delete Project"
    expect(Project.count).to eq 0
  end

  it "allows me to delete a project" do
    visit project_path(id: project.id)
    accept_confirm do
      click_link "Delete Project"
    end
    expect(page).not_to have_content "Delete Project"
    expect(Project.count).to eq 0
  end

  it "allows editing the project's title inline" do
    visit project_path(id: project.id)

    within ".dashboard-title" do
      click_button project.title
      expect(page).to have_selector("form")

      click_button "Cancel"
      expect(page).to have_selector("form", count: 0)

      click_button project.title
      expect(page).to have_selector(" form")

      fill_in "project_title", with: "New Title"

      click_button "Save"
      expect(page).to have_selector("form", count: 0)

      project.reload
      expect(project.title).to eq "New Title"
    end
  end

  context "Sub-Projects" do
    it "allows me to add sub projects" do
      visit project_path(id: project.id)
      click_link "Add Sub-Project"
      fill_in "project[title]", with: "Super Sub Project"
      click_button "Create"
      expect(page).to have_content "Project created!"
      expect(current_path).to eq projects_path
    end

    it "lists available sub projects with a link" do
      sub_project_one = FactoryBot.create(:project, title: "Sub-project 1", parent_id: project.id)
      sub_project_two = FactoryBot.create(:project, title: "Sub-project 2", parent_id: project.id)
      project_two = FactoryBot.create(:project)
      visit projects_path

      within(".project-card", text: project.title) do
        expect(page).to have_link(project.title)
        expect(page).to_not have_link(project_two.title)

        expect(page).to have_link(sub_project_one.title)
        expect(page).to have_link(sub_project_two.title)
      end
    end

    it "allow me to visit sub-projects with a link" do
      sub_project_one = FactoryBot.create(:project, title: "Sub-project 1", parent_id: project.id)
      visit projects_path

      within(".project-card", text: project.title) do
        expect(page).to have_link(project.title)
        expect(page).to have_link(sub_project_one.title)

        click_link sub_project_one.title
      end
      expect(current_path).to eq project_path(sub_project_one)
    end
  end

  context "import & Export" do
    before do
      project.stories.create(title: "php upgrade", description: "quick php upgrade")
    end

    it "allows me to export a CSV", js: false do
      visit project_path(id: project.id)
      find("#import-export").click

      click_on "Export"
      expect(page.response_headers["Content-Type"]).to eql "text/csv"
      expect(page.source).to include("php upgrade")
    end

    it "allows me to export a CSV" do
      visit project_path(id: project.id)
      find("#import-export").click

      click_on "Export"
      expect(page.source).to include("php upgrade")
    end

    it "allows me to import a CSV" do
      visit project_path(id: project.id)
      find("#import-export").click
      page.attach_file("file", (Rails.root + "spec/fixtures/test.csv").to_s)
      click_on "Import"
      expect(project.stories.count).to be > 1
      expect(project.stories.map(&:title).join).to include("php upgrade")
      expect(page.text).to include("success")
      expect(page.current_path).to eql project_path(project.id)
    end

    it "allows me to update existing stories on import" do
      csv_path = (Rails.root + "tmp/stories.csv").to_s
      story = project.stories.first
      csv_content = "id,title,description,position\n#{story.id},#{story.title},blank!,#{story.position}"
      File.write(csv_path, csv_content)

      story_count = project.stories.count
      visit project_path(id: project.id)
      find("#import-export").click
      page.attach_file("file", csv_path)
      click_on "Import"
      expect(project.stories.count).to be story_count
      expect(project.stories.map(&:description).join).to_not include("quick")
    end
  end

  context "hierarchy sidebar" do
    context "with sub projects" do
      let!(:sub_project1) { FactoryBot.create(:project, parent: project) }
      let!(:sub_project2) { FactoryBot.create(:project, parent: project) }

      it "renders a sidebar" do
        visit project_path(project)
        within "aside.hierarchy" do
          expect(page).to have_selector("a", text: project.title)
          expect(page).to have_selector("a", text: sub_project1.title)
          expect(page).to have_selector("a", text: sub_project2.title)
        end

        visit project_path(sub_project1)
        within "aside.hierarchy" do
          expect(page).to have_selector("a", text: project.title)
          expect(page).to have_selector("a", text: sub_project1.title)
          expect(page).to have_selector("a", text: sub_project2.title)
        end

        visit project_path(sub_project2)
        within "aside.hierarchy" do
          expect(page).to have_selector("a", text: project.title)
          expect(page).to have_selector("a", text: sub_project1.title)
          expect(page).to have_selector("a", text: sub_project2.title)
        end
      end
    end

    context "with no sub projects" do
      it "renders no sidebar" do
        visit project_path(project)

        expect(page).not_to have_selector("aside.hierarchy")
      end
    end
  end

  def expect_buttons_to_be_hidden
    ["Delete Project", "Add Sub-Project", "Add a Story"].each do |btn|
      expect(page).not_to have_selector(:link_or_button, btn)
    end
  end
end
