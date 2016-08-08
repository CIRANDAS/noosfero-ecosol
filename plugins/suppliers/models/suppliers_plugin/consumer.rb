class SuppliersPlugin::Consumer < SuppliersPlugin::Supplier

  self.table_name = :suppliers_plugin_suppliers

  attr_accessible :name, :email, :phone, :cell_phone, :hub_id, :address, :city, :state, :zip

  belongs_to :profile, foreign_key: :consumer_id
  belongs_to :supplier, foreign_key: :profile_id
  alias_method :consumer, :profile

  belongs_to :hub

end
