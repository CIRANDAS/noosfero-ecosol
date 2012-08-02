class DistributionPluginSessionProduct < DistributionPluginProduct

  belongs_to :session, :class_name => 'DistributionPluginSession'

  has_many :ordered_products, :class_name => 'DistributionPluginOrderedProduct', :foreign_key => 'session_product_id', :dependent => :destroy
  has_many :in_orders, :through => :ordered_products, :source => :order

  validates_presence_of :session
  validate :session_change

  # for products in session, these are the products of the suppliers
  # p in session -> p distributed -> p from supplier
  has_many :from_2x_products, :through => :from_products, :source => :from_products

  def self.create_from_distributed(session, product)
    sp = self.new product.attributes
    sp.freeze_default_attributes product
    sp.session = session
    sp.save!
    DistributionPluginSourceProduct.create :from_product => product, :to_product => sp
    sp
  end

  def supplier_products
    from_2x_products
  end

  def total_quantity_asked
    self.ordered_products.sum(:quantity_asked)
  end
  def total_price_asked
    self.ordered_products.sum(:price_asked)
  end
  def total_parcel_quantity
    #FIXME: convert units
    total_quantity_asked
  end
  def total_parcel_price
    supplier_products.sum(:price) * total_parcel_quantity
  end

  def buy_price
    supplier_product.price
  end
  def buy_unit
    supplier_product.unit
  end
  def sell_unit
    unit
  end

  # session products freezes properties and don't use
  # the original
  DEFAULT_ATTRIBUTES.each do |a|
    define_method "default_#{a}" do
      nil
    end
  end

  FROOZEN_DEFAULT_ATTRIBUTES = DEFAULT_ATTRIBUTES

  def freeze_default_attributes(from_product)
    FROOZEN_DEFAULT_ATTRIBUTES.each do |a|
      self[a.to_s] = from_product.send a
    end
  end

  protected

  def session_change
    errors.add :session_id, "session can't change" if session_id_changed? and not new_record?
  end

end
