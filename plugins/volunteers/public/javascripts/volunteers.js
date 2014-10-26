volunteers = {

  periods: {
    load: function() {
      jQuery('#volunteers-periods .period').each(function() {
        volunteers.periods.applyCalendrial(this)
      })
      jQuery('#period-new input').prop('disabled', true)
    },

    new: function() {
      var period = jQuery('#volunteers-periods-template').html()
      period = jQuery(period)
      period.find('input').prop('disabled', false)
      this.applyCalendrial(period)
      return period
    },

    add: function() {
      jQuery('.periods').append(this.new())
    },

    remove: function(link) {
      link = jQuery(link)
      var period = link.parents('.period')
      period.find('input[name*=_destroy]').prop('value', '1')
      period.hide()
    },

    applyCalendrial: function(period) {
      options = {isoTime: true}
      jQuery(period).find('.date-select, .time-select').calendricalDateTimeRange(options)
    },

  },

};
