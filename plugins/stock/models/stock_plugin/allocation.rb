class StockPlugin::Allocation < ActiveRecord::Base

  belongs_to :place, :class_name => 'StockPlugin::Place'
  belongs_to :product, :class_name => 'ProductPlugin::Product'

  validates_presence_of :place
  validates_presence_of :product
  validates_numericality_of :quantity, :allow_nil => true

  extend CurrencyHelper::ClassMethods
  has_number_with_locale :quantity

  before_validation :check_place
  after_create :update_product_counter
  after_destroy :update_product_counter

  protected

  def update_product_counter
    self.product.update_stored
  end

  def check_place
    if self.place.nil? && self.product && self.product.stock_places.count == 0
      self.place = StockPlugin::Place.create! profile_id: self.product.profile_id, name: 'default', description: 'default place'
    end
  end
end
