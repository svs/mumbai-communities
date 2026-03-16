require 'rails_helper'

RSpec.describe TodoItem, type: :model do
  fixtures :users, :wards, :categories

  let(:issue) do
    Issue.create!(
      title: "Test Issue",
      description: "Test description",
      ward: wards(:ward_A),
      created_by: users(:user_one),
      status: "open"
    )
  end

  def build_todo(attrs = {})
    TodoItem.new({ title: "Test todo", issue: issue, position: 1 }.merge(attrs))
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(build_todo).to be_valid
    end

    it "requires a title" do
      expect(build_todo(title: nil)).not_to be_valid
    end
  end

  describe "defaults" do
    it "defaults completed to false" do
      todo = build_todo
      expect(todo.completed).to be false
    end
  end

  describe "status methods" do
    it "#complete! marks as completed" do
      todo = build_todo
      todo.save!
      todo.complete!
      expect(todo.completed).to be true
    end

    it "#uncomplete! marks as not completed" do
      todo = build_todo(completed: true)
      todo.save!
      todo.uncomplete!
      expect(todo.completed).to be false
    end

    it "#toggle! flips completed state" do
      todo = build_todo
      todo.save!
      todo.toggle!
      expect(todo.completed).to be true
      todo.toggle!
      expect(todo.completed).to be false
    end
  end

  describe "scopes" do
    before do
      issue.todo_items.create!(title: "Done", completed: true, position: 2)
      issue.todo_items.create!(title: "Not done", completed: false, position: 1)
    end

    it ".completed returns completed items" do
      expect(TodoItem.completed.pluck(:title)).to eq(["Done"])
    end

    it ".incomplete returns incomplete items" do
      expect(TodoItem.incomplete.pluck(:title)).to eq(["Not done"])
    end

    it ".ordered sorts by position" do
      expect(TodoItem.ordered.pluck(:title)).to eq(["Not done", "Done"])
    end
  end
end
