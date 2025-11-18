class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 散歩記録との関連付け（1人のユーザーは複数の散歩記録を持つ）
  # dependent: :destroy は、ユーザーが削除されたときに関連する散歩記録も一緒に削除する
  has_many :walks, dependent: :destroy
end
