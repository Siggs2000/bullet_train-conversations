require "bullet_train/super_load_and_authorize_resource/version"
require "bullet_train/super_load_and_authorize_resource/engine"

class Account::ConversationsController < Account::ApplicationController
  include Conversations::BaseController

  account_load_and_authorize_resource :conversation, through: BulletTrain::Conversations.parent_association, through_association: :conversations, except: [:create]

  def author
    :membership
  end

  def author_helper
    :current_membership
  end
end
