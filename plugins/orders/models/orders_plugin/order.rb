require "plugins/orders/lib/orders_plugin/serialize_synced_data"

class OrdersPlugin::Order < Noosfero::Plugin::ActiveRecord

  belongs_to :profile
  belongs_to :consumer, :class_name => 'Profile'

  has_many :products, :class_name => 'OrdersPlugin::OrderedProduct', :foreign_key => :order_id, :dependent => :destroy,
    :include => [{:product => [{:profile => [:domains]}]}], :order => 'products.name ASC'

  belongs_to :supplier_delivery, :class_name => 'DeliveryPlugin::Method'
  belongs_to :consumer_delivery, :class_name => 'DeliveryPlugin::Method'

  named_scope :for_consumer, lambda { |consumer| {
    :conditions => {:consumer_id => consumer ? consumer.id : nil} }
  }

  extend CodeNumbering::ClassMethods
  code_numbering :code

  validates_presence_of :profile
  STATUSES = ['draft', 'planned', 'confirmed', 'cancelled', 'accepted', 'shipped']
  validates_inclusion_of :status, :in => STATUSES
  before_validation :default_values

  extend OrdersPlugin::SerializedSyncedData::ClassMethods
  sync_serialized_field :consumer do |profile|
    {:name => profile.name, :email => profile.contact_email, :contact_phone => profile.contact_phone}
  end
  sync_serialized_field :supplier_delivery
  sync_serialized_field :consumer_delivery
  serialize :payment_data, Hash
  sync_serialized_field :products do |products|
    hash = {}; products.each do |product|
       hash[product.id] = {:name => product.name, :price => product.price.to_f, :quantity_asked => product.quantity_asked}
    end
    hash
  end

  named_scope :draft, :conditions => {:status => 'draft'}
  named_scope :planned, :conditions => {:status => 'planned'}
  named_scope :confirmed, :conditions => {:status => 'confirmed'}
  named_scope :cancelled, :conditions => {:status => 'cancelled'}
  def draft?
    self.status == 'draft'
  end
  def planned?
    self.status == 'planned'
  end
  def confirmed?
    self.status == 'confirmed'
  end
  def cancelled?
    self.status == 'cancelled'
  end
  def current_status
    return 'forgotten' if forgotten?
    return 'open' if open?
    self['status']
  end

  def may_edit? admin_action = false
    self.draft? or admin_action
  end


  STATUS_MESSAGE = {
   'open' => 'orders_plugin.models.order.in_progress',
   'forgotten' => 'orders_plugin.models.order.not_confirmed',
   'planned' => 'orders_plugin.models.order.planned',
   'confirmed' => 'orders_plugin.models.order.confirmed',
   'cancelled' => 'orders_plugin.models.order.cancelled',
   'accepted' => 'orders_plugin.models.order.accepted',
   'shipped' => 'orders_plugin.models.order.shipped',
  }
  def status_message
    I18n.t STATUS_MESSAGE[current_status]
  end

  def total_quantity_asked
    self.products.collect(&:quantity_asked).inject(0){ |sum,q| sum+q }
  end
  def total_price_asked
    self.products.collect(&:price_asked).inject(0){ |sum,q| sum+q }
  end

  def parcel_quantity_total
    #TODO
    total_quantity_asked
  end
  def parcel_price_total
    #TODO
    total_price_asked
  end

  def products_by_supplier
    self.products.group_by{ |p| p.supplier.abbreviation_or_name }
  end

  extend CurrencyHelper::ClassMethods
  has_number_with_locale :total_quantity_asked
  has_number_with_locale :parcel_quantity_total
  has_currency :total_price_asked
  has_currency :parcel_price_total

  protected

  def default_values
    self.status ||= 'draft'
  end

end
