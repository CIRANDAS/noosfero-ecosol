
orders = {

  product: {

    edit: function () {
      toggle_edit.editing().find('.more').toggle(toggle_edit.isEditing());
    },

    quantity_keyup: function(context, event) {
      if (event.keyCode == 13) {
        orders.product.submit();
        return false;
      }
    },

    submit: function(context, url) {
      var container = jQuery(context).parents('.order-products-container');
      var product = jQuery(context).parents('.ordered-product');
      var quantity_asked = product.find('.quantity-edit input');

      loading_overlay.show(container);
      jQuery.post(url, {'ordered_product[quantity_asked]': quantity_asked.val()});
    },
  },

  admin: {

    toggle_edit: function () {
      toggle_edit.editing().find('.box-edit').toggle(toggle_edit.isEditing());
      sortable_table.edit_arrow_toggle(toggle_edit.editing(), toggle_edit.isEditing());
    },
  },

};
