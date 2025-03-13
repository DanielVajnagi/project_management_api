class User < ApplicationRecord
  has_many :projects, dependent: :destroy

  devise :database_authenticatable, :registerable, :recoverable, :validatable
  acts_as_token_authenticatable

  validates :password_confirmation, presence: true, on: :create
  validates :authentication_token, uniqueness: true, allow_nil: true
end
