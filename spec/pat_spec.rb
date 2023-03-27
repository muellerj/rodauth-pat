require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do
  let(:app) { base_app }

  it "ensures everything is wired up correctly" do
    app.route do |r|
      r.rodauth
      r.get("public") { "i can see you" }
      rodauth.require_authentication
      r.get("protected") { "secret!" }
    end

    visit "/public"
    expect(page).to have_content "i can see you"

    visit "/protected"
    expect(page).not_to have_content "secret!"
    expect(page.current_path).to eq "/login"
  end

  it "protects resources with personal access tokens" do
    app.plugin :rodauth do
      enable :personal_access_tokens
    end

    app.route do |r|
      r.rodauth
      rodauth.require_token_authentication
      r.get("protected") { "secret!" }
    end

    visit "/protected"
    expect(page).not_to have_content "secret!"
    expect(page.status_code).to eq 401
  end
end
