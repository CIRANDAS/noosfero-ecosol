
currency = {
  list: null,

  find: function(id) {
    id = parseInt(id);
    return currency.list.find(function(c) { return c.id == id; });
  },
};

currency.accept = {
  query: null,
  last_query: null,
  query_url: null,
  typing: false,
  pending: false,

  load: function (hint) {
    jQuery('#search-query').hint(hint);
  },

  search: function (input, url) {
    currency.accept.typing = true;
    setTimeout(currency.accept.search_timeout, 200);
    currency.accept.query = input.value;
    currency.accept.query_url = url;
  },

  search_timeout: function () {
    if (!currency.accept.query ||
        (currency.accept.last_query && currency.accept.query == currency.accept.last_query))
      return;
    currency.accept.typing = false;
    currency.accept.pending = true;
    currency.accept.last_query = currency.accept.query;
    jQuery.get(currency.accept.query_url, {query: currency.accept.query}, function (data) {
      currency.accept.pending = false;
      jQuery('#currency-search').html(data);
    });
  },
};

currency.product = {

  priceRow: null,
  discountRow: null,

  setId: function (pc) {
    pc.id = pc.currency_id;
    return pc;
  },

  load: function(options) {
    currency.list = options.currencies;
    currency.product.priceRow = jQuery('#price-row');
    currency.product.discountRow = jQuery('#discount-row');

    currency.product.add('price', options.prices.map(currency.product.setId));
    currency.product.add('discount', options.discounts.map(currency.product.setId));

    jQuery('#price-currency-select').change(function () {
      var item = currency.find(jQuery(this).val());
      currency.product.add('price', [item]);
    });
    jQuery('#discount-currency-select').change(function () {
      var item = currency.find(jQuery(this).val());
      currency.product.add('discount', [item]);
    });
  },

  add: function(field, currencies) {
    currency.product[field+'Row'].after(currency.product.template(field, currencies));
  },

  template: function (field, currencies) {
    var template = jQuery('#currency-template');
    return _.template(template.html(), {field: field, currencies: currencies});
  },
};

// don't strip underscore templates within ruby templates
String.prototype.stripScripts = function () { return this; };

window.addedScripts = window.addedScripts || [];
function addScript(src, onload) {
  if (window.addedScripts.indexOf(src) != -1)
    return;
  window.addedScripts.push(src);
  jQuery.ajax({async: false, url: src, success: function(js) { jQuery.globalEval(js); }});
  if (onload != undefined)
    onload();
}

currency.underscore_settings = function () {
  // underscore use of <@ instead of <%
  _.templateSettings = {
    interpolate: /\<\@\=(.+?)\@\>/gim,
    evaluate: /\<\@(.+?)\@\>/gim
  };
};

// from http://stackoverflow.com/questions/17033397/javascript-strings-with-keyword-parameters
String.prototype.format = function(obj) {
  return this.replace(/%\{([^}]+)\}/g,function(_,k){ return obj[k] });
};

