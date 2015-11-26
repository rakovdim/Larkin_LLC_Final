class TxUtils
  def self.execute_transacted_action (action)
    ActiveRecord::Base.transaction do
      action.call
    end
  end
end