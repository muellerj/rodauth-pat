require_relative "spec_helper"

RSpec.describe "Rodauth personal access token feature", type: :feature do
  it "can ensure everything is wired up correctly" do
    # TODO: continue
    # rodauth do
    #   enable :login, :personal_access_tokens
    # end
    app.route do |r|
      r.get "protected" do
        "secret!"
      end
    end

    visit "/protected"
    expect(page).to have_content "secret!"
  end
end
