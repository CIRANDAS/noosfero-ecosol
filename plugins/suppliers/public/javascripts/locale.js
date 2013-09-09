if (typeof locale === 'undefined') {

locale = 'pt'; //FIXME: don't hardcode
standard_locale = 'en';
code_locale = 'code';
locale_info = {
  'code': {
    'currency': {
      'delimiter': '',
      'separator': '.',
      'decimals': null,
    }
  },
  'en': {
    'currency': {
      'delimiter': ',',
      'separator': '.',
      'decimals': 2,
    }
  },
  'pt': {
    'currency': {
      'delimiter': '.',
      'separator': ',',
      'decimals': 2,
    }
  },
}

function localize_currency(value, to, from) {
  if (!to)
    to = locale;
  if (!from)
    from = standard_locale;
  var lvalue = unlocalize_currency(value, from);
  from = standard_locale;
  lvalue = lvalue.toFixed(locale_info[to].currency.decimals);
  lvalue = lvalue.replace(locale_info[from].currency.delimiter, locale_info[to].currency.delimiter);
  lvalue = lvalue.replace(locale_info[from].currency.separator, locale_info[to].currency.separator);
  return lvalue;
}

function unlocalize_currency(value, from) {
  if (!value)
    return 0;
  if (!from)
    from = locale;
  var lvalue = value.toString();
  var to = code_locale;
  lvalue = lvalue.replace(locale_info[from].currency.delimiter, locale_info[to].currency.delimiter);
  lvalue = lvalue.replace(locale_info[from].currency.separator, locale_info[to].currency.separator);
  return parseFloat(lvalue);
}

}
