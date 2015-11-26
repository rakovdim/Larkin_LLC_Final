class Load < ActiveRecord::Base
  enum status: [:not_planned, :planned_for_delivery, :in_delivery, :delivered]
  enum delivery_shift: [:morning, :afternoon, :evening]
  after_initialize :set_defaults

  has_many :order_releases, -> { order(stop_order_number: :asc) }, :autosave => true
  belongs_to :truck

  def total_volume
    total_volume = 0
    order_releases.each do |order_release|
      total_volume = total_volume+order_release.volume
    end
    total_volume
  end

  # def total_volume
  #   total_volume = 0
  #   order_releases.each do |order_release|
  #     if order.delivery?
  #       total_volume = total_volume - order_release.volume
  #     else
  #       total_volume = total_volume + order_release.volume
  #     end
  #   end
  #   total_volume
  # end

  def self.find_by_order_id(order_id)
    Load.joins(:order_releases).where('order_releases.id = ?', order_id).first
  end

  private


  def set_defaults
    self.status = Load.statuses[:not_planned] if self.new_record?
  end
end