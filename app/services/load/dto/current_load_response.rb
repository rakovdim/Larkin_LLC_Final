class CurrentLoadResponse
  attr_accessor :load, :all_trucks

  def initialize (load, all_trucks)
    @load = load
    @all_trucks = all_trucks
  end
end