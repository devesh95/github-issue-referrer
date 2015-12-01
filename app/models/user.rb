require 'json'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:github]

  has_many :issues

  def self.from_omniauth(auth)
    # print out github information for debugging
    # puts JSON.pretty_generate(auth)
    
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.email = auth.info.email
      user.nickname = auth.info.nickname
      user.auth = auth.credentials.token
      user.password = Devise.friendly_token[0,20]
    end
  end
end
