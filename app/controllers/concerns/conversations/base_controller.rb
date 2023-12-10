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

  def account_load_and_authorize_resource(model, options, old_options = {})
  # options are now required, because you have to have at least a 'through' setting.

  # we used to support calling this method with a signature like this:
  #
  #   `account_load_and_authorize_resource [:oauth, :twitter_account], :team`
  #
  # however this abstraction was too short-sighted so we've updated this method to accept the exact same method
  # signature as cancancan's original `load_and_authorize_resource` method.
  if model.is_a?(Array)
    raise "Bullet Train has depreciated this method of calling `account_load_and_authorize_resource`. Read the comments on this line of source for more details."
  end

  # this is providing backward compatibility for folks who are calling this method like this:
  #   account_load_and_authorize_resource :thing, through: :team, through_association: :scaffolding_things
  # i'm going to deprecate this at some point.
  if options.is_a?(Hash)
    through = options[:through]
    options.delete(:through)
  else
    through = options
    options = old_options
  end

  # fetch the namespace of the controller. this should generally match the namespace of the model, except for the
  # `account` part.
  namespace = model_namespace_from_controller_namespace

  tried = []
  begin
    # check whether the parent exists in the model namespace.
    model_class_name = (namespace + [model.to_s.classify]).join("::")
    model_class_name.constantize
  rescue NameError
    tried << model_class_name
    if namespace.any?
      namespace.pop
      retry
    else
      raise "Oh no, it looks like your call to 'account_load_and_authorize_resource' is broken. We tried #{tried.join(" and ")}, but didn't find a valid class name."
    end
  end

  # treat through as an array even if the user only specified one parent type.
  through_as_symbols = through.is_a?(Array) ? through : [through]

  through = []
  through_class_names = []

  through_as_symbols.each do |through_as_symbol|
    # reflect on the belongs_to association of the child model to figure out the class names of the parents.
    unless (
             association =
               model_class_name.constantize.reflect_on_association(
                 through_as_symbol
               )
           )
      raise "Oh no, it looks like your call to 'account_load_and_authorize_resource' is broken. Tried to reflect on the `#{through_as_symbol}` association of #{model_class_name}, but didn't find one."
    end

    through_class_name = association.klass.name

    begin
      through << through_class_name.constantize
      through_class_names << through_class_name
    rescue NameError
      raise "Oh no, it looks like your call to 'account_load_and_authorize_resource' is broken. We tried to load `#{through_class_name}}` (the class name defined for the `#{through_as_symbol}` association), but couldn't find it."
    end
  end

  if through_as_symbols.count > 1 && !options[:polymorphic]
    raise "When a resource can be loaded through multiple parents, please specify the 'polymorphic' option to tell us what that controller calls the parent, e.g. `polymorphic: :imageable`."
  end

  # this provides the support we need for shallow nested resources, which
  # helps keep our routes tidy even after many levels of nesting. most people
  # i talk to don't actually know about this feature in rails, but it's
  # actually the recommended approach in the rails routing documentation.
  #
  # also, similar to `load_and_authorize_resource`, people can pass in additional
  # actions for which the resource should be loaded, but because we're making
  # separate calls to `load_and_authorize_resource` for member and collection
  # actions, we ask controllers to specify these actions separately, e.g.:
  #   `account_load_and_authorize_resource :invitation, :team, member_actions: [:accept, :promote]`
  collection_actions = options[:collection_actions] || []
  member_actions = options[:member_actions] || []

  # this option is native to cancancan and allows you to skip account_load_and_authorize_resource
  # for a specific action that would otherwise run it (e.g. see invitations#show.)
  except_actions = options[:except] || []

  collection_actions =
    (%i[index new create reorder] + collection_actions) - except_actions
  member_actions =
    (%i[show edit update destroy] + member_actions) - except_actions

  options.delete(:collection_actions)
  options.delete(:member_actions)

  # NOTE: because we're using prepend for all of these, these are written in backwards order
  # of how they'll be executed during a request!

  # 4. finally, load the team and parent resource if we can.
  prepend_before_action :load_team

  # x. this and the thing below it are only here to make a sortable concern possible.
  prepend_before_action only: member_actions do
    instance_variable_name = options[:polymorphic] || through_as_symbols[0]
    eval "@child_object = @#{model}"
    eval "@parent_object = @#{instance_variable_name}"
  end

  prepend_before_action only: collection_actions do
    instance_variable_name = options[:polymorphic] || through_as_symbols[0]
    eval "@parent_object = @#{instance_variable_name}"
    if options[:through_association].present?
      eval "@child_collection = :#{options[:through_association]}"
    else
      eval "@child_collection = :#{model.to_s.pluralize}"
    end
  end

  prepend_before_action only: member_actions do
    instance_variable_name = options[:polymorphic] || through_as_symbols[0]
    possible_sources_of_parent =
      through_as_symbols.map { |tas| "@#{model}.#{tas}" }.join(" || ")
    eval_string =
      "@#{instance_variable_name} ||= " + possible_sources_of_parent
    eval eval_string
  end

  if options[:polymorphic]
    prepend_before_action only: collection_actions do
      possible_sources_of_parent =
        through_as_symbols.map { |tas| "@#{tas}" }.join(" || ")
      eval "@#{options[:polymorphic]} ||= #{possible_sources_of_parent}"
    end
  end

  # 3. on action resource, we have a specific id for the child resource, so load it directly.
  load_and_authorize_resource model,
    options.merge(
      class: model_class_name,
      only: member_actions,
      prepend: true,
      shallow: true
    )

  # 2. only load the child resource through the parent resource for collection actions.
  load_and_authorize_resource model,
    options.merge(
      class: model_class_name,
      through: through_as_symbols,
      only: collection_actions,
      prepend: true,
      shallow: true
    )

  # 1. load the parent resource for collection actions only. (we're using shallow routes.)
  # since a controller can have multiple potential parents, we have to run this as a loop on every possible
  # parent. (the vast majority of controllers only have one parent.)

  through_class_names.each_with_index do |through_class_name, index|
    load_and_authorize_resource through_as_symbols[index],
      options.merge(
        class: through_class_name,
        only: collection_actions,
        prepend: true,
        shallow: true
      )
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
