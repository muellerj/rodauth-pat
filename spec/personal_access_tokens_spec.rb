require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do

  let(:app) { base_app }
  let(:user) { DB[:accounts].first(email: "foo@example.com") }

  describe "base setup" do
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
  end

  describe "personal access tokens" do

    before do
      app.plugin :rodauth do
        enable :personal_access_tokens
      end

      app.route do |r|
        r.rodauth
        r.get("protected") do
          rodauth.require_token_authentication
          "secret!"
        end
      end
    end

    it "rejects requests without Authentication header flatly" do
      visit "/protected"
      expect(page.status_code).to eq 401
      expect(page).not_to have_content "secret!"
    end

    it "allows viewing existing tokens" do
      DB[:personal_access_tokens].insert \
        id: user[:id],
        name: "Token A",
        key: "foobar",
        expires_at: Time.now + 60 * 60 * 24 * 365
      visit "/personal-access-tokens"
      login
      expect(page).to have_content "My tokens"
      expect(page).to have_content "Token A"
    end

    it "allows expiring existing tokens" do
      DB[:personal_access_tokens].insert \
        id: user[:id],
        name: "Token A",
        key: "foobar",
        expires_at: Time.now + 60 * 60 * 24 * 365
      visit "/personal-access-tokens"
      login
      click_button "Revoke"
      expect(page).to have_content "Success!"
      expect(page).to have_content "Token A"
      expect(page).to have_content "Revoked"
    end

    it "creating new tokens" do
      visit "/new-personal-access-token"
      login
      expect(page).to have_content "New Personal Access Token"
      fill_in "Name", with: "Token A"
      click_button "Create"
      expect(page).to have_content "Success!"
      expect(page).to have_content "Token A"
    end

    it "allows access if there is a matching, non-expired, non-revoked token" do
      DB[:personal_access_tokens].insert \
        id: user[:id],
        name: "Token A",
        key: "foobar",
        expires_at: Time.now + 60 * 60 * 24 * 365

      page.driver.header "Authentication", "Bearer: foobar"
      visit "/protected"
      expect(page.status_code).to eq 200
      expect(page).to have_content "secret!"
    end

    it "disallows access for expired tokens" do
      DB[:personal_access_tokens].insert \
        id: user[:id],
        name: "Token A",
        key: "foobar",
        expires_at: Time.now - 1

      page.driver.header "Authentication", "Bearer: foobar"
      visit "/protected"
      expect(page.status_code).to eq 401
      expect(page).not_to have_content "secret!"
    end

    it "disallows access for revoked tokens" do
      DB[:personal_access_tokens].insert \
        id: user[:id],
        name: "Token A",
        key: "foobar",
        revoked_at: Time.now - 1,
        expires_at: Time.now + 60 * 60 * 24 * 365

      page.driver.header "Authentication", "Bearer: foobar"
      visit "/protected"
      expect(page.status_code).to eq 401
      expect(page).not_to have_content "secret!"
    end
  end
end
