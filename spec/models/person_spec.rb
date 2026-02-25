require 'rails_helper'

RSpec.describe Person, type: :model do
  fixtures :wards, :prabhags

  let(:ward) { wards(:ward_A) }

  describe "validations" do
    it "requires a name" do
      person = Person.new(name: nil)
      expect(person).not_to be_valid
      expect(person.errors[:name]).to include("can't be blank")
    end

    it "is valid with just a name" do
      person = Person.new(name: "Ramesh Pawar")
      expect(person).to be_valid
    end
  end

  describe "roles" do
    it "can have multiple roles" do
      person = Person.create!(name: "Ramesh Pawar", phone: "9870040562")

      person.roles.create!(roleable: ward, role_name: "assistant_commissioner")
      person.roles.create!(roleable: ward, role_name: "ward_officer")

      expect(person.roles.count).to eq(2)
    end

    it "can be attached to different entities" do
      person = Person.create!(name: "Sujata Sanap", phone: "9870040562")
      prabhag = prabhags(:prabhag_A_225)

      person.roles.create!(roleable: ward, role_name: "corporator")
      person.roles.create!(roleable: prabhag, role_name: "corporator")

      expect(person.roles.where(roleable_type: "Ward").count).to eq(1)
      expect(person.roles.where(roleable_type: "Prabhag").count).to eq(1)
    end
  end

  describe "scopes" do
    it ".with_role finds people by role name" do
      ac = Person.create!(name: "AC Person")
      ac.roles.create!(roleable: ward, role_name: "assistant_commissioner")

      corp = Person.create!(name: "Corporator Person")
      corp.roles.create!(roleable: ward, role_name: "corporator")

      results = Person.with_role("assistant_commissioner")
      expect(results).to include(ac)
      expect(results).not_to include(corp)
    end
  end
end
