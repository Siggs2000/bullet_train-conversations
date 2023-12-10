module Conversations::BaseController
  extend ActiveSupport::Concern

  # GET /account/conversations/:id
  # GET /account/conversations/:id.json
  def show
    @menu_position = "top"
    @body_class = "conversations"
    @message = @conversation.messages.new
  end

  # POST /account/teams/:team_id/conversations
  # POST /account/teams/:team_id/conversations.json
  def create
    respond_to do |format|
      begin
        ActiveRecord::Base.transaction do
          subject = conversation_params[:subject_class].constantize.find(conversation_params[:subject_id])

          @conversation = subject.create_conversation_on_team
          @parent = @conversation.send(BulletTrain::Conversations.parent_association)

          @style = conversation_params[:style] || :conversation
          @conversation.update!(conversation_params.slice(:messages_attributes))
          @message = @conversation.messages.last
          authorize! :create, @message

          format.turbo_stream { render('account/conversations/messages/create') }
          format.html { redirect_back(fallback_location: [:account, @conversation, :conversations_messages]) }
          format.json { render :show, status: :created, location: [:account, @parent, @conversation] }
        end
      rescue ActiveRecord::ActiveRecordError, CanCan::AccessDenied => e
        format.html { redirect_back(fallback_location: [:account, current_team], alert: e.message)  }
        format.json { render json: e.message, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def conversation_params
    strong_params = params.require(:conversation).permit(
      :subject_class,
      :subject_id,
      :style,
      messages_attributes: [:parent_message_id, :body]
      # 🚅 super scaffolding will insert new fields above this line.
      # 🚅 super scaffolding will insert new arrays above this line.
    )

    # 🚅 super scaffolding will insert processing for new fields above this line.

    strong_params[:messages_attributes]['0'][author] = send(author_helper)
    strong_params
  end
end
