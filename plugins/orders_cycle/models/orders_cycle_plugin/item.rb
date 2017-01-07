class OrdersCyclePlugin::Item < OrdersPlugin::Item

  has_one :supplier, through: :product

  # see also: repeat_product
  attr_accessor :repeat_cycle

  # OVERRIDE OrdersPlugin::Item
  belongs_to :order, class_name: '::OrdersCyclePlugin::Order', foreign_key: :order_id, touch: true
  belongs_to :sale, class_name: '::OrdersCyclePlugin::Sale', foreign_key: :order_id, touch: true
  belongs_to :purchase, class_name: '::OrdersCyclePlugin::Purchase', foreign_key: :order_id, touch: true

  # WORKAROUND for direct relationship
  belongs_to :offered_product, foreign_key: :product_id, class_name: 'OrdersCyclePlugin::OfferedProduct'
  has_many :from_products, through: :offered_product
  has_one :from_product, through: :offered_product
  has_many :to_products, through: :offered_product
  has_one :to_product, through: :offered_product
  has_many :sources_supplier_products, through: :offered_product
  has_one :sources_supplier_product, through: :offered_product
  has_many :supplier_products, through: :offered_product
  has_one :supplier_product, through: :offered_product
  has_many :suppliers, through: :offered_product
  has_one :supplier, through: :offered_product

  after_save :update_order
  after_save :change_purchases, if: :cycle
  before_destroy :remove_purchase_item, if: :cycle

  def cycle
    return nil unless defined? self.order.cycle
    self.order.cycle
  end

  # what items were selled from this item
  def selled_items
    self.order.cycle.selled_items.where(profile_id: self.consumer.id, orders_plugin_item: {product_id: self.product_id})
  end
  # what items were purchased from this item
  def purchased_items
    self.order.cycle.purchases.where(consumer_id: self.profile.id)
  end

  # override
  def repeat_product
    distributed_product = self.from_product
    return unless self.repeat_cycle and distributed_product
    self.repeat_cycle.products.where(from_products_products: {id: distributed_product.id}).first
  end

  def update_order
    self.order.create_transaction
  end

  protected

  def change_purchases
    return unless ["orders", 'purchases'].include? self.cycle.status
    return if self.order.status == 'draft'

    if id_changed?
      self.sale.add_purchase_item self
    elsif defined? quantity_consumer_ordered_was or defined? quantity_supplier_accepted_was
      self.sale.update_purchase_item self
    end
  end

  def remove_purchase_item
    return unless supplier_product = self.product.supplier_product
    return unless purchase = supplier_product.orders_cycles_purchases.for_cycle(self.order.cycle).first

    self.order.remove_purchases_items self, purchase
  end

end
