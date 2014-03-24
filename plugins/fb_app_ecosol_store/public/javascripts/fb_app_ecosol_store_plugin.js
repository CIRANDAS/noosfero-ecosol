fb_app_ecosol_store = {

  selected_empreendimento: null,

  init_autocomplete: function() {

      var self = this;

      var profilesSearch = new Bloodhound({
          datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
          queryTokenizer: Bloodhound.tokenizers.whitespace,
          remote: '/plugin/fb_app_ecosol_store/search?query=%QUERY'
      });

      profilesSearch.initialize();

      var input = jQuery('[name=fb_store]');

      input.typeahead(null, {
          name: 'fb_search_store',
          displayKey: 'name',
          source: profilesSearch.ttAdapter()
      });

      input.on('typeahead:selected typeahead:autocompleted', function(object, datum){
        self.selected_empreendimento = datum
      });

      input.on('keydown', function() {
          self.selected_empreendimento = null
      });

      jQuery('#fb_store_add_profile').on('click',this.add_empreendimento.bind(this));
  },

  add_empreendimento: function(evt) {
    if (evt != null && evt != void 0) { evt.preventDefault(); evt.stopPropagation();}
    if (this.selected_empreendimento != null) {
        empreendimentos.push(this.selected_empreendimento);
        this.selected_empreendimento = null;
        jQuery('[name=fb_store]').val('');
        this.redraw_tabela_empreendimentos();
    }
  },

  addJS: function(url) {
    var script = document.createElement('script'); script.type = 'text/javascript'; script.src = url;
    document.getElementsByTagName('head')[0].appendChild(script);
  },

  init_admin: function() {
    if (jQuery('#fb_store_admin_page').length > 0) {
        this.init_integration_type_selection();
        this.init_autocomplete();
        this.redraw_tabela_empreendimentos();
        //init commit button
        jQuery('#fb_commit_btn').on('click',this.commit.bind(this));
    }
  },

  init_integration_type_selection: function() {
      var func_on_radio_change;

      func_on_radio_change = function(evt) {
        var radio_elements = jQuery('[name=fb_integration_type]');

        radio_elements.each(function(key,elm) {
            if (elm.checked) {
                jQuery('#fb_integration_type_'+elm.value).show();
            } else {
                jQuery('#fb_integration_type_'+elm.value).hide();
            }
        })
      };

      jQuery('[name=fb_integration_type]').each(function(key,radio_elm) {
        var $radio_elm = jQuery(radio_elm);
        $radio_elm.on('change',func_on_radio_change);
        $radio_elm.trigger('change');
      })

      if (empreendimentos.length > 0) {
          jQuery('[name=fb_integration_type][value=profiles]').click()
      } else {
          jQuery('[name=fb_integration_type][value=query]').click()

      }
  },

  redraw_tabela_empreendimentos: function() {
      var i, tbody, tr_html, tr, remove_button, self;
      self = this;
      tbody = jQuery('#fb_tabela_empreendimentos');
      tbody.empty();
      for (i=0;i<empreendimentos.length;i++) {
          tr_html  = '<tr>';
          tr_html += '<td>'+empreendimentos[i].name+'</td>';
          tr_html += '<td class="remove-btn-holder"></td>';
          tr_html += '</tr>';
          tr = jQuery(tr_html);
          tbody.append(tr);
          remove_button = jQuery('<button data-profile-pos="'+i+'">Remover</button>');
          remove_button.on('click',function(evt) {
            var pos = parseInt(jQuery(evt.target).data('profile-pos'));
            empreendimentos.splice(pos,1);
            self.redraw_tabela_empreendimentos();
          });
          tr.find('.remove-btn-holder').append(remove_button);
      }
  },

  commit: function(evt) {
      if (evt != null && evt != void 0) { evt.preventDefault(); evt.stopPropagation();}

      var profile_ids = []
      for (var i=0;i<empreendimentos.length;i++) {
          profile_ids.push(empreendimentos[i].id)
      }

      var data = {
          integration_type: jQuery( "[name=fb_integration_type]:checked" ).val(),
          keyword: jQuery('[name=fb_keyword]').val(),
          profile_ids: profile_ids,
          page_id: window.page_id,
      }

      jQuery.ajax({
          url: '/plugin/fb_app_ecosol_store/admin',
          type: 'post',
          dataType: 'json',
          data: data,
          success: function(data) {
            display_notice('Aba instalada!');
          },
          error: function() {
              alert('Erro!')
          }
      });

  },

  fb: {
    id: '',
    page_tab_next: '',

    init: function(id, next) {
      this.id = id;
      this.page_tab_next = next;

      window.fbAsyncInit = function() {
        FB.init({
          appId: id,
          status: true,
          cookie: true,
          xfbml: true
        });

        fb_app_ecosol_store.fb.size_change();
        jQuery(document).on('DOMNodeInserted', fb_app_ecosol_store.fb.size_change);
      };
    },

    size_change: function() {
      FB.Canvas.setSize({height: jQuery('body').height()+100});
    },

    add_tab: function () {
      FB.ui({
        method: 'pagetab',
      }, function(response){
        var i=0;
        var url = fb_app_ecosol_store.base_url + "/admin?";
        jQuery.each(response.tabs_added, function(tab,v) {
          url += 'page_id['+(i++)+']='+tab+'&';
        });
        window.location.href = url;
      });
    },

    login: function() {
      FB.getLoginStatus(function(response) {
        if (response.status === 'connected') {
          fb_app_ecosol_store.fb.add_tab();
        } else {
          FB.login(function(response) {
            if (response.authResponse) {
              fb_app_ecosol_store.fb.add_tab();
            } else {
              alert('Infelizmente, sem sua autorização não poderemos inserir a loja do cirandas no seu facebook');
            }
          });
        }
      });
    },
  },
};

jQuery('document').ready(function(){
  fb_app_ecosol_store.init_admin();
});


