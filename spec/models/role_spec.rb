require 'rails_helper'

RSpec.describe Role, type: :model do
  fixtures :wards, :prabhags

  let(:ward) { wards(:ward_A) }

  describe "validations" do
    it "requires a person" do
      role = Role.new(roleable: ward, role_name: "corporator")
      expect(role).not_to be_valid
    end

    it "requires a roleable" do
      person = Person.create!(name: "Test Person")
      role = Role.new(person: person, role_name: "corporator")
      expect(role).not_to be_valid
    end

    it "requires a role_name" do
      person = Person.create!(name: "Test Person")
      role = Role.new(person: person, roleable: ward, role_name: nil)
      expect(role).not_to be_valid
    end

    it "is valid with person, roleable, and role_name" do
      person = Person.create!(name: "Ramesh Pawar")
      role = Role.new(person: person, roleable: ward, role_name: "assistant_commissioner")
      expect(role).to be_valid
    end
  end

  describe "polymorphism" do
    it "can belong to a Ward" do
      person = Person.create!(name: "AC Person")
      role = Role.create!(person: person, roleable: ward, role_name: "assistant_commissioner")

      expect(role.roleable).to eq(ward)
      expect(role.roleable_type).to eq("Ward")
    end

    it "can belong to a Prabhag" do
      person = Person.create!(name: "Corporator")
      prabhag = prabhags(:prabhag_A_225)
      role = Role.create!(person: person, roleable: prabhag, role_name: "corporator")

      expect(role.roleable).to eq(prabhag)
      expect(role.roleable_type).to eq("Prabhag")
    end
  end

  describe "scopes" do
    it ".active returns roles without ended_at or with future ended_at" do
      person = Person.create!(name: "Test")
      active_role = Role.create!(person: person, roleable: ward, role_name: "corporator")
      expired_role = Role.create!(person: person, roleable: ward, role_name: "ward_officer", ended_at: 1.day.ago)

      expect(Role.active).to include(active_role)
      expect(Role.active).not_to include(expired_role)
    end
  end
end
