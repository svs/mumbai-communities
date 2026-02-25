require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "validations" do
    subject { Category.new(name: "Unique Test Name", slug: "unique-test-slug") }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe "slug generation" do
    it "auto-generates slug from name when blank" do
      category = Category.create!(name: "Water Supply")
      expect(category.slug).to eq("water-supply")
    end

    it "does not overwrite an explicit slug" do
      category = Category.create!(name: "Water Supply", slug: "water")
      expect(category.slug).to eq("water")
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      category = Category.new(name: "Roads", slug: "roads")
      expect(category.to_param).to eq("roads")
    end
  end

  describe ".ordered" do
    it "orders by position then name" do
      # Fixtures are loaded; test ordering includes them
      ordered = Category.ordered.to_a
      positions = ordered.map(&:position)
      expect(positions).to eq(positions.sort)
    end
  end
end
