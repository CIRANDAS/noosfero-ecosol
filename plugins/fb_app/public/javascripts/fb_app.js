fb_app = {
  current_url: '',

  locales: {

  },

  config: {
    url_prefix: '',
    save_auth_url: '',
    show_login_url: '',

    init: function() {

    },

  },

  timeline: {
    app_id: '',
    //app_scope: 'publish_actions',
    app_scope: '',

    loading: function() {
      jQuery('#fb-app-connect-status').empty().addClass('loading').height(150)
    },

    connect: function() {
      this.loading();
      fb_app.fb.scope = this.app_scope
      //fb_app.fb.init(this.app_id, 'fb_app.fb.connect()')
      fb_app.fb.connect()
    },

    disconnect: function() {
      this.loading();
      fb_app.auth.receive({status: 'not_authorized'})
    },

    connect_to_another: function() {
      this.loading();
      fb_app.fb.connect_to_another()
    },
  },

  page_tab: {
    app_id: '',
    next_url: '',

    init: function() {
    },

    config: {

      init: function() {
        this.change_type($('select#page_tab_config_type'))

      },

      edit: function(button) {
        var page_tab = button.parents('.page-tab')
        page_tab.find('form').toggle(400)
      },

      remove: function(button, url) {
        var page_tab = button.parents('.page-tab')
        var name = page_tab.find('#page_tab_name').val()
        jQuery('.modal-button-yes')
          .attr('target_url',url)
          .attr('target_id','#'+page_tab.attr('id'))
        jQuery('#fb-app-modal-catalog-name').text(name)
        noosfero.modal.html(jQuery('#fb-app-modal-wrap').html())
      },

      remove_confirmed: function(el) {
        el = jQuery(el)
        jQuery.post(el.attr('target_url'), function() {
          var page_tab = jQuery(el.attr('target_id'))
          page_tab.remove()
        })
      },

      close: function(evt) {
       if (evt != null && evt != void 0) { evt.preventDefault(); evt.stopPropagation();}
        noosfero.modal.close()
        jQuery('#content').html('').addClass('loading')
        window.location.href = fb_app.current_url
      },

      validate_catalog_submission: function(form) {
        if (form.find('#page_tab_name').val().trim()=='') {
          noosfero.modal.html('<div id="fb-app-error">'+fb_app.locales.error_empty_name+'</div>')
          return false
        } else {
          var selected_type = form.find('#page_tab_config_type').val()
          if (form.find('.config-type-'+selected_type+' input').val().trim()=='') {
            noosfero.modal.html('<div id="fb-app-error">'+fb_app.locales.error_empty_settings+'</div>')
            return false
          }
        }
        return true
      },

      add: function (form) {
        if (!this.validate_catalog_submission(form))
          return false
        // this checks if the user is using FB as a page and offer a switch
        FB.login(function(response) {
          var next_url = fb_app.page_tab.next_url + '?' + form.serialize()
          window.location.href = fb_app.fb.add_tab_url(fb_app.page_tab.app_id, next_url)
        })
        return false
      },

      save: function(form) {
        if (!this.validate_catalog_submission(form))
          return false
        jQuery(form).ajaxSubmit()
        return false
      },

      change_type: function(select) {
        select = jQuery(select)
        var page_tab = select.parents('.page-tab')
        var config_selector = '.config-type-'+select.val()
        var config = page_tab.find(config_selector)
        var to_show = config
        var to_hide = page_tab.find('.config-type:not('+config_selector+')')

        to_show.show().
          find('input').prop('disabled', false)
        to_show.find('.tokenfield').removeClass('disabled')
        to_hide.hide().
          find('input').prop('disabled', true)
      },

      profile: {

        onchange: function(input) {
          if (input.val())
            input.removeAttr('placeholder')
          else
            input.attr('placeholder', input.attr('data-placeholder'))
        },
      },
    },

  },

  auth: {
    status: 'not_authorized',

    load: function (html) {
      jQuery('#fb-app-settings').html(html)
    },
    loadLogin: function (html) {
      if (this.status == 'not_authorized')
        jQuery('#fb-app-connect').html(html).removeClass('loading')
      else
        jQuery('#fb-app-login').html(html)
    },

    receive: function(response) {
      fb_app.fb.authResponse = response
      fb_app.auth.save(response)
    },

    transformParams: function(response) {
      var authResponse = response.authResponse
      if (!authResponse)
        return {auth: {status: response.status}}
      else
        return {
          auth: {
            status: response.status,
            access_token: authResponse.accessToken,
            expires_in: authResponse.expiresIn,
            signed_request: authResponse.signedRequest,
            provider_user_id: authResponse.userID,
          }
        }
    },

    showLogin: function(response) {
      jQuery.get(fb_app.config.show_login_url, this.transformParams(response), this.loadLogin)
    },

    save: function(response) {
      jQuery.post(fb_app.config.save_auth_url, this.transformParams(response), this.load)
    },
  },


  fb: {
    id: '',
    scope: '',

    init: function(app_id, asyncInit) {

      window.fbAsyncInit = function() {
        FB.init({
          appId: app_id,
          status: true,
          cookie: true,
          xfbml: true
        })

        fb_app.fb.size_change()
        jQuery(document).on('DOMNodeInserted', fb_app.fb.size_change)

        if (asyncInit)
          jQuery.globalEval(asyncInit)
      }
    },

    size_change: function() {
      FB.Canvas.setSize({height: jQuery('body').height()+100})
    },

    redirect_to_tab: function(pageID) {
      FB.api('/'+pageID, function(response) {
        window.location.href = response.link + '?sk=app_' + fb_app.fb.id
      })
    },

    add_tab_url: function (app_id, next_url) {
      return 'https://www.facebook.com/dialog/pagetab?' + jQuery.param({app_id: app_id, next: next_url})
    },

    connect: function() {
      FB.login(function(response) {
        fb_app.auth.receive(response)
      }, {scope: fb_app.fb.scope})
    },

    connect_to_another: function() {
      this.logout(this.connect)
    },

    logout: function(callback) {
      FB.logout(function(response) {
        if (callback) callback(response)
      })
    },

    // not to be used
    delete: function() {
      FB.api("/me/permissions", "DELETE", function(response) {
        fb_app.auth.receive({status: 'not_authorized'})
      })
    },

    checkLoginStatus: function() {
      FB.getLoginStatus(function(response) {
        fb_app.auth.showLogin(response)
      })
    },

  },

}


