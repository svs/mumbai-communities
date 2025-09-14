class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :assigned_prabhags, class_name: 'Prabhag', foreign_key: 'assigned_to_id'
  has_many :assigned_tickets, class_name: 'Ticket', foreign_key: 'assigned_to_id'
  has_many :created_tickets, class_name: 'Ticket', foreign_key: 'created_by_id'

  # Location relationships
  belongs_to :ward, foreign_key: 'ward_code', primary_key: 'ward_code', optional: true
  belongs_to :prabhag, optional: true

  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
    end
  end

  def current_assignments
    assigned_prabhags.where(status: ['assigned', 'submitted'])
  end
  
  def active_tickets
    assigned_tickets.where(status: ['assigned', 'in_progress', 'submitted'])
  end
  
  def completed_tickets
    assigned_tickets.completed
  end
  
  def overdue_tickets
    assigned_tickets.overdue
  end

  # Location methods
  def has_location?
    ward_code.present? && prabhag_id.present?
  end

  def location_confirmed?
    location_confirmed_at.present?
  end

  def set_location(street_address, ward_code, prabhag_id, lat = nil, lng = nil)
    update!(
      street_address: street_address,
      ward_code: ward_code,
      prabhag_id: prabhag_id,
      latitude: lat,
      longitude: lng,
      location_confirmed_at: Time.current
    )
  end

  def location_summary
    return "Location not set" unless has_location?

    parts = []
    parts << ward.name if ward
    parts << "Ward #{ward_code}" if ward_code
    parts.join(", ")
  end

  def needs_location_setup?
    !has_location? || !location_confirmed?
  end
end
