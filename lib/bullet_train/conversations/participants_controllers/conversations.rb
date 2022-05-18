# Create the dynamically named controller with eval, and then we can reference it.
eval %{
  class #{BulletTrain::Conversations.participant_namespace}::ConversationsController < BulletTrain::Conversations.participant_parent_controller.constantize
  end
}

"#{BulletTrain::Conversations.participant_namespace}::ConversationsController".constantize.class_eval do
  include ::Conversations::BaseController

  account_load_and_authorize_resource :conversation, through: BulletTrain::Conversations.participant_parent_association, through_association: :conversations, except: [:create]

  def author
    :participant
  end

  def author_helper
    BulletTrain::Conversations.current_participant_helper_method
  end
end
