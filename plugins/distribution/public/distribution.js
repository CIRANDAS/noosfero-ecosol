var _editing = jQuery();
var _inner_editing = jQuery();
var _isInner = false;

function setEditing(value) {
  _editing = jQuery(value);
}
function editing() {
  return _editing.first();
}
function isEditing() {
  return editing().first().hasClass('edit');
}

function distribution_edit_arrow_toggle(context, toggle) {
  arrow = jQuery(context).hasClass('actions-circle') ? jQuery(context) : jQuery(context).find('.actions-circle');

  arrow.toggleClass('edit', toggle);
  return arrow.hasClass('edit');
}


function distribution_calculate_price(price_input, margin_input, base_price_input) {
  var price = parseFloat(jQuery(price_input).val());
  var base_price = parseFloat(jQuery(base_price_input).val());
  var margin = parseFloat(jQuery(margin_input).val());

  var value = distribution_currency( base_price + (margin / 100) * base_price );
  jQuery(price_input).val( isNaN(value) ? base_price_input.val() : value );
}
function distribution_calculate_margin(margin_input, price_input, base_price_input) {
  var price = parseFloat(jQuery(price_input).val());
  var base_price = parseFloat(jQuery(base_price_input).val());
  var margin = parseFloat(jQuery(margin_input).val());

  var value = distribution_currency( ((price - base_price) / base_price ) * 100 );
  jQuery(margin_input).val( isFinite(value) ? value : '' );
}

/* ----- session stuff  ----- */

function distribution_in_session_order_toggle(context) {
  container = jQuery(context).hasClass('session-orders') ? jQuery(context) : jQuery(context).parents('.session-orders');
  container.toggleClass('show');
  container.find('.order-content').toggle();
  distribution_edit_arrow_toggle(container);
}

/* ----- ends session stuff  ----- */

/* ----- delivery stuff  ----- */

function distribution_delivery_view_toggle() {
  jQuery('#delivery-method-choose, #delivery-method-edit').toggle();
}

/* ----- ends delivery stuff  ----- */

/* ----- category select stuff  ----- */

var category = null;

function distribution_category_toggle_view(edit, view) {
  edit.find('.category-selected').toggle(view == 1);
  edit.find('.category-hierarchy').toggle(view != 0);
  edit.find('.category-type-select').toggle(view == 2);
  edit.find('.field-box').toggle(view == 0);
  distribution_our_product_css_align();
}

function distribution_subcategory_select(context) {
  edit = jQuery(context).parents('.category-edit');
  option = context.options[context.selectedIndex];
  edit.find('.category-hierarchy .type').text(jQuery(option).text());

  distribution_category_toggle_view(edit, 1);
}

function distribution_category_reselect_sub() {
  edit.find('.category-hierarchy .type').text('');
  distribution_category_toggle_view(edit, 2);
}

function distribution_category_select_another(context) {
  edit = jQuery(context).parents('.category-edit');
  edit.find('#product_category_id').tokenInput('clear');

  distribution_category_toggle_view(edit, 0);
}

function distribution_category_reselect(context, item) {
  jQuery(context).parents('.category').nextAll('.category').remove();
  jQuery(context).parents('.category').siblings('.type').text('');
  edit = jQuery(context).parents('.category-edit');
  edit.find('#product_category_id').val(item.id);
  category = item;
  distribution_category_template_type_select(edit);
  distribution_category_toggle_view(edit, 2);
}

function distribution_category_template_hierarchy(edit) {
  edit.find('.category-hierarchy div').html(_.template(edit.find('.category-hierarchy script').html(), {cat: category}));
}
function distribution_category_template_type_select(edit, selected) {
  edit.find('.category-type-select div').html(_.template(edit.find('.category-type-select script').html(), {cat: category, selected: selected}));
  if (selected)
    edit.find('select').get(0).onchange();
}
function distribution_category_select(item) {
  category = item;
  edit = jQuery(this).parents('.category-edit');
  distribution_category_template_hierarchy(edit);
  distribution_category_template_type_select(edit);

  distribution_category_toggle_view(edit, 2);
}

/* ----- end category select stuff  ----- */

/* ----- our products stuff  ----- */

function distribution_our_product_enable_if_disabled(event) {
  target = jQuery(event.target);
  if (target.is('input[type=text][disabled], select[disabled]')) {
    product = jQuery(target).parents('.our-product');
    default_checkbox = jQuery(jQuery.grep(product.find('input[type=checkbox][for]'), function(element, index) {
        return jQuery(element).attr('for').indexOf(target.attr('id')) >= 0; 
    }));
    default_checkbox.attr('checked', null);
    distribution_our_product_toggle_referred(default_checkbox);
    target.focus();
  }
}

function distribution_our_product_toggle_referred(context) {
  var p = jQuery(context).parents('.box-edit');
  var referred = p.find(jQuery(context).attr('for'));

  jQuery.each(referred, function(i, value) {
    value.disabled = context.checked;

    if (value.disabled) {
      jQuery(value).attr('oldvalue', jQuery(value).val());
      jQuery(value).val(value.hasAttribute('defaultvalue')
        ? jQuery(value).attr('defaultvalue') : p.find('#'+value.id.replace('product', 'product_supplier_product')).val());
    } else {
      jQuery(value).val(jQuery(value).attr('oldvalue'));
    }

    if (value.onkeyup)
      value.onkeyup();
  });
  referred.first().focus();
}
function distribution_our_product_sync_referred(context) {
  var p = jQuery(context).parents('.box-edit');
  var referred = p.find('#'+context.id.replace('product_supplier_product', 'product')).get(0);
  if (referred && referred.disabled) {
    jQuery(referred).val(jQuery(context).val());

    if (referred.onkeyup)
      referred.onkeyup();
  }
}
function distribution_our_product_add_missing_products(context, url) {
  supplier = jQuery('#our-product-add').find('#product_supplier_id');
  jQuery.post(url, jQuery(supplier).serialize(), function() {
  });
}
function distribution_our_product_add_change_supplier(context, url) {
  jQuery('#our-product-add').load(url, jQuery(context).serialize(), function() {
    distribution_our_product_toggle_edit();
  });
}
function distribution_our_product_add_from_product(context, url, data) {
  jQuery('#our-product-add').load(url, data, function() {
    distribution_our_product_toggle_edit();
  });
}

function distribution_our_product_pmsync(context, to_price) {
  var p = jQuery(context).parents('.our-product');
  var margin_input = p.find('#product_margin_percentage');
  var price_input = p.find('#product_price');
  var buy_price_input = p.find('#product_supplier_product_price');
  var default_margin_input = p.find('#product_default_margin_percentage');

  if (!margin_input.get(0)) //own product don't have a margin
    return;

  if (to_price || price_input.get(0).disabled)
    distribution_calculate_price(price_input, margin_input, buy_price_input);
  else {
    var oldvalue = parseFloat(margin_input.val());
    distribution_calculate_margin(margin_input, price_input, buy_price_input);
    var newvalue = parseFloat(margin_input.val());
    if (newvalue != oldvalue) {
      var checked = newvalue == parseFloat(margin_input.attr('defaultvalue'));
      default_margin_input.attr('checked', checked ? 'checked' : null);
      margin_input.get(0).disabled = checked;
    }
  }
}

function distribution_our_product_css_align() {
  var distributed = editing().find('.our-product-distributed-column');
  var use_original = editing().find('.our-product-use-original-column');
  var supplied = editing().find('.our-product-supplied-column');

  use_original.height(distributed.height());
  supplied.height(distributed.height());

  if (supplied.length > 0)
    supplied.find('.price-block').css('top', distributed.find('.price-block').position().top);

  use_original.find('input[type=checkbox]').each(function(index, checkbox) {
    checkbox = jQuery(checkbox);
    checkbox.css('top', distributed.find(checkbox.attr('for')).first().position().top - use_original.find('.guideline').position().top);
  });
}

/* ----- ends our products stuff  ----- */

/* ----- order stuff  ----- */

function distribution_order_products_toggle(fields, toggle) {
  jQuery.each(fields, function(index, field) {
    var p = jQuery(field).parents('.order-session-product');
    p.toggle(toggle);
    //v = p.is(':visible');
    //toggle ? (!v ? p.fadeIn() : 0) : (v ? p.fadeOut() : 0);
  });
}

function distribution_order_filter_products(text) {
  text = text.toLowerCase();
  fields = jQuery('#session-products-for-order .box-field');
  results = jQuery.grep(fields, function(field, index) {
    fieldText = jQuery(field).text().toLowerCase();
    supplierText = jQuery(field).parents('.supplier-table').find('.supplier').text().toLowerCase();

    matchField = fieldText.indexOf(text) > -1;
    matchSupplier = supplierText.indexOf(text) > -1;
    return matchField || matchSupplier;
  });
  jQuery('#session-products-for-order .supplier-table').show();
  distribution_order_products_toggle(jQuery(fields), false);
  distribution_order_products_toggle(jQuery(results), true);

  jQuery('#session-products-for-order .supplier-table').each(function(index, supplier) {
    jQuery(supplier).toggle(jQuery(supplier).find('.order-session-product:visible').length > 0 ? true : false);
  });
}

function distribution_order_filter() {
  distribution_order_filter_products(jQuery(this).text());
  jQuery(this).parents('#order-filter').find('input').val(jQuery(this).text());
}

/* ----- ends order stuff  ----- */

/* ----- supplier stuff  ----- */

/* ----- ends supplier stuff  ----- */

/* ----- session editions stuff  ----- */

function distribution_session_product_pmsync(context, to_price) {
  p = jQuery(context).parents('.session-product-edit');
  margin = p.find('#product_margin_percentage');
  price = p.find('#product_price');
  buy_price = p.find('#product_buy_price');
  if (to_price)
    distribution_calculate_price(price, margin, buy_price);
  else
    distribution_calculate_margin(margin, price, buy_price);
}

/* ----- ends session editions stuff  ----- */

/* ----- table sorting stuff  ----- */

jQuery('.table-header .box-field').live('click', function () {
  this.ascending = !this.ascending;
  header = jQuery(this).parents('.table-header');
  content = header.siblings('.table-content');
  jQuerySort(content.children('.value-row'), {find: '.'+this.classList[1], ascending: this.ascending});

  arrow = header.find('.sort-arrow').length > 0 ? header.find('.sort-arrow') : jQuery('<div class="sort-arrow"/>').appendTo(header);
  arrow.toggleClass('desc', !this.ascending).css({
    top: jQuery(this).position().top + jQuery(this).height() - 1,
    left: jQuery(this).position().left + parseInt(jQuery(this).css('margin-left')) + parseInt(jQuery(this).css('padding-left'))
  });
});

/* ----- ends table sorting stuff  ----- */

/* ----- toggle edit stuff  ----- */

function distribution_supplier_add_link() {
  if (isEditing())
    distribution_value_row_toggle_edit();
  setEditing(jQuery('#supplier-add'));
  distribution_value_row_toggle_edit();
}
function distribution_supplier_toggle_edit() {
  if (editing().is('#supplier-add'))
    editing().toggle(isEditing());
  editing().find('.box-view').toggle(!isEditing());
  editing().find('.box-edit').toggle(isEditing());
}
function distribution_in_session_order_toggle_edit() {
  editing().find('.box-edit').toggle(isEditing());
  distribution_edit_arrow_toggle(editing(), isEditing());
}
function distribution_our_product_add_link() {
  if (isEditing())
    distribution_value_row_toggle_edit();
  setEditing(jQuery('#our-product-add'));
  distribution_value_row_toggle_edit();
}
function distribution_our_product_toggle_edit() {
  if (editing().is('#our-product-add'))
    editing().toggle(isEditing());
  editing().find('.box-view').toggle(!isEditing());
  editing().find('.box-edit').toggle(isEditing());

  distribution_our_product_css_align();
}
function distribution_session_product_edit() {
  editing().find('.box-edit').toggle(isEditing());
}
function distribution_order_session_product_toggle() {
  editing().find('.box-edit').toggle(isEditing());
  editing().find('.quantity-label').toggle(!isEditing());
  editing().find('.quantity-entry').toggle(isEditing());
}
function distribution_ordered_product_edit() {
  editing().find('.more-actions').toggle(isEditing());
  if (isEditing())
    editing().find('.product-quantity input').focus();
}

function distribution_value_row_toggle_edit() {
  editing().toggleClass('edit');
  eval(editing().attr('toggleedit'));
  if (!isEditing()) {
    if (_editing.length > 1)
      setEditing(jQuery(_editing[1]));
    else
      setEditing(jQuery());
  }
}
function distribution_value_row_reload() {
  distribution_value_row_toggle_edit();
}
function distribution_locate_value_row(context) {
  return jQuery(context).hasClass('value-row') ? jQuery(context) : jQuery(context).parents('.value-row');
}

function target_isToggle(target) {
  return (jQuery(target).hasClass('box-edit-link') && !isEditing()) || 
    jQuery(target).hasClass('toggle-edit') || jQuery(target).parents().hasClass('toggle-edit');
}
jQuery(document).click(function(event) {
  var isToggle = target_isToggle(event.target);
  var out = distribution_locate_value_row(event.target).length == 0;
  if (!isToggle && out && isEditing()) {
    distribution_value_row_toggle_edit();
    return false;
  }
  return true;
});

function openAnchor() {
  el = jQuery(window.location.hash);
  distribution_value_row_reload();
  if (el.hasClass('value-row')) {
    setEditing(el);
    distribution_value_row_toggle_edit();
  }
}
jQuery(document).ready(openAnchor);
jQuery(window).bind('hashchange', openAnchor);

jQuery('.plugin-distribution .value-row').live('click', function (event) {
  var value_row = distribution_locate_value_row(event.target);
  var now_isInner = value_row.length > 1;

  if (jQuery(event.target).hasClass('toggle-ignore-event'))
    return true;

  var isToggle = target_isToggle(event.target);
  var isAnother = value_row.get(0) != editing().get(0) || (now_isInner && !_isInner);
  if (now_isInner && !_isInner)
    setEditing(value_row);
  _isInner = now_isInner;

  if (!isToggle && value_row.attr('without-click-edit') != undefined)
    return;

  if (isToggle) {
    if (isAnother) 
      distribution_value_row_toggle_edit();
    setEditing(value_row);
    distribution_value_row_toggle_edit();

    return false;
  } else if (isAnother || !isEditing()) {
    if (isEditing())
      distribution_value_row_toggle_edit();
    setEditing(value_row);
    if (!isEditing())
      distribution_value_row_toggle_edit();

    return false;
  }

  return true;
});
jQuery('.plugin-distribution .value-row').live('mouseenter', function () {
  if (jQuery(this).attr('without-hover') != undefined)
    return;
  jQuery(this).addClass('hover');
});
jQuery('.plugin-distribution .value-row').live('mouseleave', function () {
  if (jQuery(this).attr('without-hover') != undefined)
    return;
  jQuery(this).removeClass('hover');
});

/* ----- ends toggle edit stuff  ----- */

/* ----- infrastructure stuff  ----- */

function distribution_currency(value) {
  return parseFloat(value).toFixed(2);
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

Array.prototype.diff = function(a) {
  return this.filter(function(i) {return !(a.indexOf(i) > -1);});
};
Array.prototype.sum = function(){
  for(var i=0,sum=0;i<this.length;sum+=this[i++]);
    return sum;
}
Array.prototype.max = function(){
  return Math.max.apply({}, this);
}
Array.prototype.min = function(){
  return Math.min.apply({}, this);
}

function jQuerySort(elements, options) {
  if (typeof options === 'undefined') options = {};
  options.ascending = typeof options.ascending === 'undefined' ? 1 : (options.ascending ? 1 : -1);
  var list = elements.get();
  list.sort(function(a, b) {
    var compA = (options.find ? jQuery(a).find(options.find) : jQuery(a)).text().toUpperCase();
    var compB = (options.find ? jQuery(b).find(options.find) : jQuery(b)).text().toUpperCase();
    return options.ascending * ((compA < compB) ? -1 : (compA > compB) ? 1 : 0);
  });
  parent = elements.first().parent();
  jQuery.each(list, function(index, element) { parent.append(element); });
}

_.templateSettings = {
  evaluate: /\{\{([\s\S]+?)\}\}/g,
  interpolate: /\{\{=([\s\S]+?)\}\}/g,
  escape: /\{\{-([\s\S]+?)\}\}/g
}

/* ----- ends infrastructure stuff  ----- */
