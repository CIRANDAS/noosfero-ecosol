function sessionProductSetFocus(id) {
  jQuery(id).find('input').focus();
}

function distribution_order_session_product_toggle(el, selected) {
  el.find('.value-row').toggleClass('clicked', selected);
  el.find('.session-product-more-info').toggle(selected);
  el.find('.quantity-label').toggle(!selected);
  el.find('.quantity-entry').toggle(selected);
}
var clicked = jQuery();
function distribution_order_session_product_click() {
  it = jQuery(this);
  if (clicked == it)
    return false;
  distribution_order_session_product_toggle(clicked, false);
  distribution_order_session_product_toggle(it, true);
  clicked = it;

  return false;
}
jQuery(document).click(function(event) {
  if (jQuery(event.target).parents('.ordered-product-more-actions').length > 0) //came from anchor click!
    return;
  distribution_order_session_product_toggle(clicked, false);
});

function distribution_order_session_product_hover() {
  jQuery(this).find('.value-row').toggleClass('selected');
}

function distribution_ordered_product_hover() {
  jQuery(this).toggleClass('selected');
  jQuery(this).find('.ordered-product-more-actions').toggle();
}

function distribution_our_product_toggle_referred(context, referred, options) {
  p = jQuery(context).parents('.our-product-edit');
  referred = p.find(jQuery(context).attr('for'));

  jQuery.each(referred, function(i, value) {
    value.disabled = context.checked;
    if (value.disabled) {
      jQuery(value).attr('oldvalue', jQuery(value).val());
      jQuery(value).val(value.hasAttribute('defaultvalue')
        ? jQuery(value).attr('defaultvalue') : p.find('#'+value.id.replace('product', 'product_supplier_product')).val());
    } else {
      jQuery(value).val(jQuery(value).attr('oldvalue'));
    }
  });
}

function distribution_our_product_add() {
  jQuery('#our-product-add').show();
}

function distribution_our_product_toggle_edit(context) {
  row = jQuery(context).parents('.value-row');
  row.find('.our-product-view').toggle();
  row.find('.our-product-edit').toggle();
  row.toggleClass('edit');
}

function distribution_node_margin_toggle_edit(content) {
  c = jQuery('#node-margin-percentage');
  i = c.find('input[type=text]');
  c.toggleClass('edit view');
  c.find('.toggle-button').toggle();
  i.toggleDisabled();
  c.toggleClass('empty', i.val().empty());
  c.toggleClass('non-empty', !i.val().empty());
}

var distribution_session_product_editing = jQuery();
function distribution_plugin_session_product_edit(id) {
  editing = jQuery(id);
  stop_editing = editing.index(distribution_session_product_editing) ? false : true;

  distribution_session_product_editing.removeClass('session-product-editing');
  distribution_session_product_editing.find('.session-product-edit').hide();
  if (!stop_editing) {
    editing.addClass('session-product-editing');
    editing.find('.session-product-edit').show();
    distribution_session_product_editing = editing;
  }
}

(function($) {
  $.fn.toggleDisabled = function() {
    return this.each(function() { 
      this.disabled = !this.disabled;
    });
  };
})(jQuery);

jQuery('.plugin-distribution input[type=checkbox]').live('change', function () {
  jQuery(this).attr('checked', this.checked ? 'checked' : null);
  return false;
});

