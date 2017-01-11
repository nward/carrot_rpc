# Methods similar to rails controller actions for RpcClient
module CarrotRpc::ClientActions
  # Convience method as a resource alias for index action.
  # To customize, override the method in your class.
  #
  # @param params [Hash] the arguments for the method being called.
  def index(params)
    remote_call("index", params)
  end

  # Convience method as a resource alias for show action.
  # To customize, override the method in your class.
  #
  # @param params [Hash] the arguments for the method being called.
  def show(params)
    remote_call("show", params)
  end

  # Convience method as a resource alias for create action.
  # To customize, override the method in your class.
  #
  # @param params [Hash] the arguments for the method being called.
  def create(params)
    remote_call("create", params)
  end

  # Convience method as a resource alias for update action.
  # To customize, override the method in your class.
  #
  # @param params [Hash] the arguments for the method being called.
  def update(params)
    remote_call("update", params)
  end

  # Let us define class methods in this included module. Used below.
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Remove the default methods above.
    def no_default_methods
      CarrotRpc::ClientActions.instance_methods.each do |instance_method|
        undef_method instance_method
      end
    end
  end
end
