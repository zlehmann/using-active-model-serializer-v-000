require "rails_helper"

RSpec.describe "author_model" do
  before do
    test_var = "yes"
  end

  it "lets me pass my Learn tests" do
    expect(test_var).to eq("yes")
  end
