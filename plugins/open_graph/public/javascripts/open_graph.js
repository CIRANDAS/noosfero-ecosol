
open_graph = {

  track: {

    config: {
      reload: false,

      view: {
        form: null,
      },

      init: function() {
        this.view.form = jQuery('#track-form form')

        if (!this.reload) {
          this.view.form.find('.panel-heading').each(function(i, context) {
            open_graph.track.config.headingToggle(context)
          })
        }

        this.watchChanges()
      },

      watchChanges: function() {
        $(window.document).ready(function () {
          open_graph.track.config.view.form.find('input').change(open_graph.track.config.save)
        })
      },

      submit: function(form) {
        form = $(form)
        form.ajaxSubmit()
      },

      save: function() {
        open_graph.track.config.view.form.submit()
      },

      headingToggle: function(context, open) {
        var panel = $(context).parents('.panel')
        var panelHeading = panel.find('.panel-heading')
        var panelBody = panel.find('.panel-body')
        var parentCheckbox = panel.find('.config-check')
        var configButton = panel.find('.config-button')
        var input = panel.find('.track-config-toggle')
        if (open === undefined)
          open = input.val() == 'true'
        // on user enable (open is not undefined), open if open-on-enable
        else if (panelHeading.hasClass('open-on-enable'))
          this.open(context)
        if (!open)
          panelBody.collapse('hide')

        configButton.toggle(open)
        parentCheckbox.toggleClass('fa-toggle-on', open)
        parentCheckbox.toggleClass('fa-toggle-off', !open)
        input.prop('value', open)
        input.trigger('change')
      },

      open: function(context) {
        var panel = $(context).parents('.panel')
        var panelBody = panel.find('.panel-body')
        panelBody.collapse('show')
      },

      toggle: function(context, event) {
        var panel = $(context).parents('.panel')
        var panelBody = panel.find('.panel-body')
        var checkboxes = panelBody.find('input[type=checkbox]')
        var open = panel.find('.track-config-toggle').val() == 'true'
        open = !open;

        checkboxes.prop('checked', open)

        this.headingToggle(context, open)
        return false;
      },

      toggleObjectType: function(checkbox) {
        checkbox = $(checkbox)
        this.toggleParent(checkbox)
        checkbox.siblings("input[name*='[_destroy]']").val(!checkbox.is(':checked'))
      },

      toggleParent: function(context) {
        var panel = $(context).parents('.panel')
        var panelBody = panel.find('.panel-body')
        var checkboxes = panel.find('.panel-body input[type=checkbox]')
        var profilesInput = panel.find('.panel-body .select-profiles')

        var nObjects = checkboxes.filter(':checked').length
        var nProfiles = profilesInput.length ? profilesInput.tokenfield('getTokens').length : 0;
        var nChecked = nObjects + nProfiles;
        var nTotal = checkboxes.length + nProfiles

        if (nChecked === 0) {
          this.headingToggle(context, false)
        } else {
          this.headingToggle(context, true)
        }
      },

      enterprise: {
        see_all: function(context) {
          var panel = $(context).parents('.panel')
          var panelBody = panel.find('.panel-body')
          noosfero.modal.html(panelBody.html())
        },
      },

      initAutocomplete: function(track, url, items) {
        if (!this.reload)
          return

        var selector = '#select-'+track
        var tokenField = open_graph.autocomplete.init(url, selector, items)

        tokenField
          .on('tokenfield:createdtoken tokenfield:removedtoken', function() {
            open_graph.track.config.toggleParent(this)
          }).on('tokenfield:createtoken', function(event) {
            var existingTokens = $(this).tokenfield('getTokens')
            $.each(existingTokens, function(index, token) {
              if (token.value === event.attrs.value)
                event.preventDefault()
            })
          })

        return tokenField;
      },

    },
  },

  autocomplete: {
    bloodhoundOptions: {
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      ajax: {
        beforeSend: function() {
          input.addClass('small-loading')
        },
        complete: function() {
          input.removeClass('small-loading')
        },
      },
    },
    tokenfieldOptions: {

    },
    typeaheadOptions: {
      minLength: 1,
      highlight: true,
    },

    init: function(url, selector, data, options) {
      options = options || {}
      var bloodhoundOptions = jQuery.extend({}, this.bloodhoundOptions, options.bloodhound || {});
      var typeaheadOptions = jQuery.extend({}, this.typeaheadOptions, options.typeahead || {});
      var tokenfieldOptions = jQuery.extend({}, this.tokenfieldOptions, options.tokenfield || {});

      var input = $(selector)
      bloodhoundOptions.remote = {
        url: url,
        replace: function(url, uriEncodedQuery) {
          return jQuery.param.querystring(url, {query:uriEncodedQuery});
        },
      }
      var engine = new Bloodhound(bloodhoundOptions)
      engine.initialize()

      tokenfieldOptions.typeahead = [typeaheadOptions, { displayKey: 'label', source: engine.ttAdapter() }]

      var tokenField = input.tokenfield(tokenfieldOptions)
      input.tokenfield('setTokens', data)

      return input
    },
  },
}

