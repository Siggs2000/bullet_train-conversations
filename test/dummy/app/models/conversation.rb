class Conversation < ApplicationRecord
  include Conversations::Base
  # 🚅 add concerns above.

  belongs_to :document, class_name: 'Document', optional: true
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def subject
    document ||
    bullet_train_subjects # 🚅 add resources with conversations above.
  end

  # 🚅 add methods above.
end
