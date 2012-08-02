class DistributionPluginSession < ActiveRecord::Base
  belongs_to :node, :class_name => 'DistributionPluginNode', :foreign_key => :node_id

  has_many :delivery_options, :class_name => 'DistributionPluginDeliveryOption', :foreign_key => :session_id, :dependent => :destroy
  has_many :delivery_methods, :through => :delivery_options, :source => :delivery_method

  has_many :orders, :class_name => 'DistributionPluginOrder', :foreign_key => :session_id, :dependent => :destroy, :order => 'id asc'
  has_many :products, :class_name => 'DistributionPluginProduct', :foreign_key => :session_id, :order => 'id asc'

  has_many :from_products, :through => :products, :order => 'id asc'
  has_many :from_nodes, :through => :products
  has_many :to_nodes, :through => :products

  has_many :ordered_suppliers, :through => :orders, :source => :suppliers
  has_many :ordered_products, :through => :orders, :source => :products
  has_many :ordered_session_products, :through => :orders, :source => :session_products, :uniq => true
  has_many :ordered_distributed_products, :through => :orders, :source => :distributed_products, :uniq => true
  has_many :ordered_supplier_products, :through => :orders, :source => :supplier_products, :uniq => true

  extend CodeNumbering::ClassMethods
  code_numbering :code, :scope => Proc.new { self.node.sessions }

  named_scope :years, :select => 'DISTINCT(EXTRACT(YEAR FROM start)) as year', :order => 'year desc'

  named_scope :not_new, :conditions => ["status <> 'new'"]
  named_scope :open, lambda {
    {:conditions => ["status = 'orders' AND ( (start <= :now AND finish IS NULL) OR (start <= :now AND finish >= :now) )",
      {:now => DateTime.now}]}
  }
  named_scope :not_open, lambda {
    {:conditions => ["NOT ( ( (start <= :now AND finish IS NULL) OR (start <= :now AND finish >= :now) ) AND status = 'orders' )",
      {:now => DateTime.now}]}
  }
  named_scope :by_month, lambda { |date| {
    :conditions => [ ':start BETWEEN start AND finish OR :finish BETWEEN start AND finish',
      { :start => date.to_time, :finish => date.to_time.change(:month => date.month+1)-1 }
    ]}
  }
  named_scope :by_year, lambda { |year| {
    :conditions => [ 'start BETWEEN :start AND :finish',
      { :start => Time.mktime(year), :finish => Time.mktime(year.to_i+1) }
    ]}
  }
  named_scope :by_range, lambda { |range| {
    :conditions => [ 'start BETWEEN :start AND :finish OR finish BETWEEN :start AND :finish',
      { :start => range.first, :finish => range.last }
    ]}
  }

  named_scope :status_open, :conditions => ["status <> 'closed'"]
  named_scope :status_closed, :conditions => ["status = 'closed'"]

  STATUS_SEQUENCE = [
    #'edition', 'call', 'orders', 'parcels', 'redistribution', 'delivery', 'close', 'closed'
    'new', 'edition', 'orders', 'closed'
  ]
  
  validates_presence_of :node, :if => :not_new?
  validates_presence_of :name, :if => :not_new?
  validates_presence_of :start, :if => :not_new?
  validates_associated :delivery_options, :if => :not_new?
  validates_inclusion_of :status, :in => STATUS_SEQUENCE, :if => :not_new?
  validates_numericality_of :margin_percentage, :allow_nil => true, :if => :not_new?
  validates_numericality_of :margin_fixed, :allow_nil => true, :if => :not_new?
  validate :validate_orders_dates, :if => :not_new?
  validate :validate_delivery_dates, :if => :not_new?

  extend SplitDatetime::ClassMethods
  split_datetime :start
  split_datetime :finish
  split_datetime :delivery_start
  split_datetime :delivery_finish

  def name_with_code
    _("%{code}. %{name}") % {
      :code => code, :name => name
    }
  end
  def total_price_asked
    self.ordered_products.sum(:price_asked)
  end
  def total_parcel_price
    #FIXME: wrong!
    self.ordered_supplier_products.sum(:price)
  end

  def step
    self.status = STATUS_SEQUENCE[STATUS_SEQUENCE.index(self.status)+1]
  end
  def passed_by?(status)
    STATUS_SEQUENCE.index(self.status) > STATUS_SEQUENCE.index(status)
  end
  def new?
    status == 'new'
  end
  def open?
    status != 'closed'
  end
  def closed?
    status == 'closed'
  end
  def orders?
    now = DateTime.now
    status == 'orders' && ( (self.start <= now && self.finish.nil?) || (self.start <= now && self.finish >= now) )
  end
  def in_delivery?
    now = DateTime.now
    passed_by('orders') && ( (self.delivery_start <= now && self.delivery_finish.nil?) || (self.delivery_start <= now && self.delivery_finish >= now) )
  end

  def products_for_order_by_supplier
    self.products.unarchived.all(:conditions => ['price > 0']).group_by{ |sp| sp.supplier }
  end
  
  def ordered_products_by_suppliers
    self.ordered_session_products.unarchived.group_by{ |p| p.supplier }.map do |supplier, products|
      total_price_asked = total_parcel_price = 0
      products.each do |product|
        total_price_asked += product.total_price_asked 
        total_parcel_price += product.total_parcel_price 
      end

      [supplier, products, total_price_asked, total_parcel_price]
    end
  end

  after_create :add_distributed_products
  def add_distributed_products
    already_in = self.products.unarchived.all
    node.products.unarchived.distributed.map do |product|
      p = already_in.find{ |f| f.from_product == product }
      unless p
        p = DistributionPluginSessionProduct.create_from_distributed(self, product)
      end
      p
    end
  end

  def destroy
    products.each{ |p| p.destroy! }
    super
  end

  protected

  before_validation :default_values
  def default_values
    self.status ||= 'edition'
  end

  before_update :step_new
  def step_new
    return if new_record?
    self.step if self.new?
  end

  def not_new?
    status != 'new'
  end

  def validate_orders_dates
    return if self.new?
    errors.add_to_base(_("Invalid orders' date range")) unless delivery_start <= delivery_finish
  end

  def validate_delivery_dates
    return if self.new?
    errors.add_to_base(_("Invalid delivery' date range")) unless start <= finish
  end

end
