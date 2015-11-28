class OrderRelease < ActiveRecord::Base
  attr_accessor :delivery_type
  enum status: [:not_planned, :planned_for_delivery, :in_delivery, :delivered]
  enum delivery_type: [:delivery, :return]
  enum delivery_shift: [:morning, :afternoon, :evening, :any_time]
  enum handling_unit_type: [:box]
  enum mode: [:TRUCKLOAD]
  after_initialize :set_defaults

  belongs_to :load

  validates :purchase_order_number, presence: true
  validates :origin_name, presence: true
  validates :origin_raw_line_1, presence: true
  validates :origin_city, presence: true
  validates :origin_country, presence: true
  validates :origin_state, presence: true
  validates :origin_zip, presence: true
  validates :destination_name, presence: true
  validates :destination_raw_line_1, presence: true
  validates :destination_city, presence: true
  validates :destination_country, presence: true
  validates :destination_state, presence: true
  validates :destination_zip, presence: true
  #validates :phone_number
  validates :handling_unit_type, presence: true
  validates :handling_unit_quantity, presence: true
  validates :volume, presence: true
  validates :status, presence: true

  validates :delivery_date, presence: true #, :if => !@custom_errors.nil? && !@custom_errors.has_key?(:delivery_date)
  validates :delivery_shift, presence: true #, :if => !@custom_errors.nil? && !@custom_errors.has_key?(:delivery_shift)
  validates :mode, presence: true #, :if => !@custom_errors.nil? && !@custom_errors.has_key?(:mode)
  validates :handling_unit_type, presence: true #, :if => !@custom_errors.nil? && !@custom_errors.has_key?(:handling_unit_type)

  validates :origin_zip, length: {is: 5}, numericality: {only_integer: true, :greater_than => 0}, :if => :origin_zip
  validates :volume, numericality: {only: true, :greater_than_or_equal_to => 0}, :if => :volume
  validates :destination_zip, length: {is: 5}, numericality: {only_integer: true, :greater_than => 0}, :if => :destination_zip
  validates :handling_unit_quantity, numericality: {only_integer: true, :greater_than_or_equal_to => 1}, :if => :handling_unit_quantity

  validate :validate_origin_dest
  validate :validate_custom_errors
  validate :validate_origin_dest_not_equal

  def add_custom_validation_error (attribute, error_message)
    ensure_hash_for_errors
    @custom_errors[attribute] = error_message
  end

  def as_json(options = {})
    result = super(options)
    result[:delivery_type] = delivery_type
    result
  end

  def delivery?
    delivery_type==OrderRelease.delivery_types.to_a[0][0]
  end

  def self.not_planned_status
    OrderRelease.statuses.to_a[0][0]
  end

  def self.planned_status
    OrderRelease.statuses.to_a[1][0]
  end

  private

  def validate_custom_errors
    ensure_hash_for_errors
    @custom_errors.each do |attribute, error_message|
      errors.add(attribute, error_message)
    end
  end

  def validate_origin_dest_not_equal
    errors.add(:origin_name, "can't be the same as Destination Name") if origin_name == destination_name
  end

  def validate_origin_dest
    if (attr_present? origin_name) && (attr_present? destination_name)
      if !(origin_name.upcase =='LARKIN LLC') and
          !(destination_name.upcase == 'LARKIN LLC')
        errors.add(:base, "Destination Name or Origin Name should be Larkin LLC")
      end
    end
  end

  def get_delivery_type
    unless origin_name.nil?
      if origin_name.upcase =='LARKIN LLC'
        OrderRelease.delivery_types.to_a[0][0]
      else
        OrderRelease.delivery_types.to_a[1][0]
      end
    end
  end


  def set_defaults
    self.status = OrderRelease.statuses[:not_planned] if self.new_record?
    self.delivery_type= get_delivery_type
  end

  def attr_present? attr
    !attr.nil? && attr.length!=0
  end

  def ensure_hash_for_errors
    if @custom_errors.nil?
      @custom_errors = {}
    end
  end
end
