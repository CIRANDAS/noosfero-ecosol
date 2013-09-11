# OLD ONES
class DistributionPlugin::Node < Noosfero::Plugin::ActiveRecord
  belongs_to :profile
end
class DistributionPluginSupplier < ActiveRecord::Base
  belongs_to :profile
  belongs_to :consumer, :class_name => 'Profile'
end
class DistributionPluginProduct < ActiveRecord::Base
  belongs_to :node, :class_name => 'DistributionPlugin::Node'
  belongs_to :supplier, :class_name => 'DistributionPluginSupplier'
end
class DistributionPluginSourceProduct < ActiveRecord::Base
  belongs_to :to_product, :class_name => 'DistributionPluginProduct'
end
class DistributionPluginDistributedProduct < DistributionPluginProduct
end
class DistributionPluginOfferedProduct < DistributionPluginProduct
end

# NEW ONES
class SuppliersPlugin::SourceProduct < Noosfero::Plugin::ActiveRecord
  belongs_to :from_product, :class_name => 'Product'
  belongs_to :to_product, :class_name => 'Product'
  has_one :supplier, :class_name => 'SuppliersPlugin::Supplier'
end
class Product
  belongs_to :profile

  has_many :sources_from_products, :class_name => 'SuppliersPlugin::SourceProduct', :foreign_key => :to_product_id
  has_many :from_products, :through => :sources_from_products, :order => 'id ASC'
end
class SuppliersPlugin::BaseProduct < Product
  validates_uniqueness_of :name, :scope => :profile_id, :allow_nil => true, :if => proc{ |p| false }
end
class SuppliersPlugin::DistributedProduct < SuppliersPlugin::BaseProduct
end
class DistributionPlugin::OfferedProduct < SuppliersPlugin::BaseProduct
end
class DistributionPlugin::OrderedProduct < Noosfero::Plugin::ActiveRecord
end
class DistributionPlugin::SessionProduct < Noosfero::Plugin::ActiveRecord
end

class MoveDistributionProductsIntoSuppliersPlugin < ActiveRecord::Migration
  def self.up
    id_translation = {}

    ::ActiveRecord::Base.transaction do
      DistributionPluginProduct.all.each do |product|
        profile = product.node.profile
        new_type = product.attributes['type']
        new_type = 'SuppliersPlugin::DistributedProduct' if new_type == 'DistributionPluginDistributedProduct'
        new_type = 'DistributionPlugin::OfferedProduct' if new_type == 'DistributionPluginOfferedProduct'
        new_type = 'Product' if product.supplier and product.supplier.profile == profile
        klass = new_type.constantize

        new_product = klass.new :enterprise => profile, :name => product.name, :price => product.price,
          :description => product.description, :available => product.active, :unit_id => product.unit_id
        new_product.product_category_id = product.category_id || ProductCategory.find_by_name('Produtos').id || ProductCategory.first.id
        if new_type != 'Product'
          # reset default_ as it has changed
          product.settings.each do |key, value|
            value = nil if key.to_s.start_with? 'default_'
            new_product.data[key] = value
          end
          new_product.data[:margin_percentage] = product.attributes['margin_percentage']
          new_product.data[:unit_detail] = product.attributes['unit_detail']
          new_product.data[:minimum_selleable] = product.attributes['minimum_selleable']
          new_product.data[:stored] = product.attributes['stored']
          new_product.data[:quantity] = product.attributes['quantity']
        end

        new_product.send :create_or_update_without_callbacks
        id_translation[product.id] = new_product.id
      end

      # move supplier_id
      add_column :distribution_plugin_source_products, :supplier_id, :integer
      DistributionPluginSourceProduct.all.each do |sp|
        next sp.destroy if sp.to_product.nil?
        sp.supplier_id = sp.to_product.supplier.id
        sp.save!
      end
      remove_column :distribution_plugin_products, :supplier_id

      rename_table :distribution_plugin_suppliers, :suppliers_plugin_suppliers
      rename_table :distribution_plugin_source_products, :suppliers_plugin_source_products
      SuppliersPlugin::SourceProduct.all.each do |sp|
        sp.update_attributes! :to_product_id => id_translation[sp.to_product_id],
          :from_product_id => id_translation[sp.from_product_id]
      end

      rename_column :distribution_plugin_ordered_products, :session_product_id, :product_id
      DistributionPlugin::OrderedProduct.all.each do |op|
        op.update_attributes! :product_id => id_translation[op.product_id]
      end

      DistributionPlugin::SessionProduct.all.each do |sp|
        sp.update_attributes! :product_id => id_translation[sp.product_id]
      end
    end

    drop_table :distribution_plugin_products
  end

  def self.down
  end
end
