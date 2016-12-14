module OrdersPlugin
  class OrderSerializer < ApplicationSerializer

    attribute :currency_unit

    attribute :admin
    attribute :actor_name
    attribute :self_supplier

    attribute :may_edit
    attribute :view_only

    attribute :status
    attribute :total_price
    attribute :remaining_total

    has_many :items
    has_many :payments

    attribute :add_url

    def currency_unit
      return unless scope.respond_to? :environment, true
      scope.send(:environment).currency_unit
    end

    def admin
      scope.instance_variable_get :@admin
    end
    def actor_name
      instance_options[:actor_name]
    end
    def self_supplier
      object.self_supplier?
    end

    def may_edit
      object.may_edit? user, admin
    end
    def view_only
      scope.instance_variable_get :@view
    end

    def total_price
      object.total_price actor_name, admin
    end

    def remaining_total
      object.remaining_total actor_name, admin
    end

    def items
      object.items.map do |item|
        ItemSerializer.new(item, scope: scope, actor_name: actor_name).to_hash
      end
    end

    def payments
      object.payments.map do |p|
        PaymentSerializer.new(p, scope: scope).to_hash
      end
    end
    def add_url
      if admin
        scope.url_for controller: :orders_plugin_admin_item, action: :add, order_id: object.id, actor_name: actor_name
      end
    end

    protected

    def user
      return unless scope.respond_to? :user, true
      scope.send :user
    end

  end
end
