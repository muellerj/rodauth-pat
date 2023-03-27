require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do
  let(:app) { base_app }

  it "can ensure everything is wired up correctly" do
    app.route do |r|
      r.get("public") { "i can see you" }
      #r.rodauth
      r.get("protected") { "secret!" }
    end

    visit "/protected"
    expect(page).to have_content "secret!"
  end
end
