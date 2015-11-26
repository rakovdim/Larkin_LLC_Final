class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    return if user.nil?
    can :index, OrderRelease if user.has_role? 'dispatcher'
    can :show, OrderRelease if user.has_role? 'dispatcher'
    can :edit, OrderRelease if user.has_role? 'dispatcher'
    can :update, OrderRelease if user.has_role? 'dispatcher'
    can :upload, OrderRelease if user.has_role? 'dispatcher'
    can :save_orders, OrderRelease if user.has_role? 'dispatcher'
    can :index, Load if user.has_role? 'dispatcher'
    can :get_available_orders, Load if user.has_role? 'dispatcher'
    can :get_planning_orders, Load if user.has_role? 'dispatcher'
    can :update_orders, Load if user.has_role? 'dispatcher'
    can :complete_load, Load if user.has_role? 'dispatcher'
    can :load_planning, Load if user.has_role? 'dispatcher'

    can :list, :all if user.has_role? 'driver'
    #can :list, :User if user.has_role 'driver'

  end
end