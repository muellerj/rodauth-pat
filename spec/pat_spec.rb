require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do
  let(:app) { base_app }

  it "can ensure everything is wired up correctly" do
    app.route do |r|
      r.rodauth
      r.get("public") { "i can see you" }
      rodauth.require_authentication
      r.get("protected") { "secret!" }
    end

    visit "/public"
    expect(page).to have_content "i can see you"
    visit "/protected"
    expect(page.current_path).to eq "/login"
  end
end
