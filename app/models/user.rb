class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :assigned_prabhags, class_name: 'Prabhag', foreign_key: 'assigned_to_id'
  has_many :assigned_tickets, class_name: 'Ticket', foreign_key: 'assigned_to_id'
  has_many :created_tickets, class_name: 'Ticket', foreign_key: 'created_by_id'

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
end
