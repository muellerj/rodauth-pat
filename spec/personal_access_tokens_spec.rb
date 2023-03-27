require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do
  let(:app) { base_app }

  before do
    DB[:personal_access_tokens].insert \
      id: DB[:accounts].returning(:id).insert(email: "foo@example.com").first[:id],
      key: "foobar",
      expires_at: Time.now + 60 * 60 * 24 * 365
  end

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
    expect(page.status_code).to eq 401
    expect(page).not_to have_content "secret!"

    page.driver.header "Authentication", "Bearer: foobar"
    visit "/protected"
    expect(page.status_code).to eq 200
    expect(page).to have_content "secret!"
  end
end
