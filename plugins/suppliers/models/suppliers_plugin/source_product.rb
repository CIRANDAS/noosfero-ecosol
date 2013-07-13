class SuppliersPlugin::SourceProduct < ActiveRecord::Base

  default_scope :include => [:from_product, :to_product]

  belongs_to :from_product, :class_name => "Product"
  belongs_to :to_product, :class_name => "Product"

  has_one :supplier, :class_name => "Profile"

  validates_presence_of :from_product
  validates_presence_of :to_product
  validates_associated :from_product
  validates_associated :to_product
  validates_numericality_of :quantity, :allow_nil => true

  def self.new_dummy attributes = {}
    source self.new attributes
  end

  alias_method :destroy!, :destroy
  def destroy
    to_product.destroy! if to_product
    destroy!
  end

end
