module Discussable
  extend ActiveSupport::Concern

  included do
    has_many :discussions, as: :discussable, dependent: :destroy
  end
end
