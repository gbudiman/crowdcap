var mosvals = function() {
  var CONST_SLACK = 4;
  var buffers = {};
  var buffer_position = 0;
  var gui_position = -1;
  var slider_a;
  var slider_b;
  var get_buffer_size = function() {
    return Object.keys(buffers).length;
  }
  var get_slack = function() {
    return get_buffer_size() - buffer_position;
  }
  var buffer_is_almost_empty = function() {
    return get_slack() < CONST_SLACK;
  }

  var attach = function() {
    var attach_mos_sliders = function() {
      var tick_formatter = function(v) {
        switch(v) {
          case 1: return 'Abysmal';
          case 2: return 'Poor';
          case 3: return 'Fair';
          case 4: return 'Good';
          case 5: return 'Excellent';
        }
      }
      slider_a = $('#mos-a-slider-container').slider({
        min: 1,
        max: 5,
        value: 3,
        tooltip_position: 'left',
        orientation: 'vertical',
        ticks: [5,4,3,2,1],
        formatter: tick_formatter,
        reversed: true,
        tooltip: 'always',
        id: 'mos-a-slider',
      })

      slider_b = $('#mos-b-slider-container').slider({
        min: 1,
        max: 5,
        value: 3,
        tooltip_position: 'right',
        orientation: 'vertical',
        ticks: [5,4,3,2,1],
        formatter: tick_formatter,
        reversed: true,
        tooltip: 'always',
        id: 'mos-b-slider'
      })

      //$('#mos-a-slider').find('.min-slider-handle').hide();
      //$('#mos-b-slider').find('.min-slider-handle').hide();
    }

    var attach_buttons = function() {
      $('#button-prev').on('click', function() {
        switch_gui(-1);
      })

      $('#button-next').on('click', function() {
        switch_gui(1);
      })
    }

    attach_mos_sliders();
    attach_buttons();
    fetch_buffered();
  }

  var disable_buttons = function(val) {
    if (val) {
      $('#button-prev').prop('disabled', true);
      $('#button-next').prop('disabled', true);
    } else {
      update_buttons_state();
    }
  }

  var fetch_buffered = function() {

    var fetch = function() {
      if (!buffer_is_almost_empty()) return;

      $.ajax({
        url: '/subjective/evals/fetch'
      }).done(function(res) {
        if (res.picture != undefined) {
          load_to_buffer(get_buffer_size(), res);
          fetch();
        }
      })
    }

    var load_to_buffer = function(id, d) {
      var is_swapped = Math.round(Math.random()) == 1 ? true : false
      var s_a;
      var s_b;
      var id_a;
      var id_b;

      if (is_swapped) {
        s_a = d.methods['1'].text
        s_b = d.methods['0'].text
        id_a = d.methods['1'].id
        id_b = d.methods['0'].id
      } else {
        s_a = d.methods['0'].text
        s_b = d.methods['1'].text
        id_a = d.methods['0'].id
        id_b = d.methods['1'].id
      }

      buffers[id] = {
        s_a: s_a,
        s_b: s_b,
        id_a: id_a,
        id_b: id_b,
        score_a: null,
        score_b: null,
        subval_id: null,
        is_swapped: is_swapped,
        picture_id: d.picture.id,
        picture_name: d.picture.name
      }

      update_gui(id);
    }

    // while (buffer_is_almost_empty()) {
    //   fetch(get_buffer_size());
    // }
    fetch();
  }

  var update_buttons_state = function() {
    $('#button-prev').prop('disabled', gui_position <= 0);
    $('#button-next').prop('disabled', gui_position + 1 == buffer_position);
  }

  var switch_gui = function(x) {
    if (x == 0) {
      update_buttons_state();
    } else {
      save_responses();
      gui_position += x;
      update_buttons_state();
      load_gui(gui_position, x);
    }
  }

  var save_responses = function() {
    var send_to_server = function() {
      var d = buffers[gui_position];
      var is_swapped = d.is_swapped;

      $.ajax({
        url: '/subjective/evals/post',
        method: 'POST',
        data: {
          a_id: is_swapped ? d.id_b : d.id_a,
          b_id: is_swapped ? d.id_a : d.id_b,
          a_score: is_swapped ? d.score_b : d.score_a,
          b_score: is_swapped ? d.score_a : d.score_b,
          subval_id: d.subval_id
        }
      }).done(function(res) {
        d.subval_id = res.id;
      })
    }

    buffers[gui_position].score_a = slider_a.slider('getValue');
    buffers[gui_position].score_b = slider_b.slider('getValue');

    send_to_server();
  }

  var get_buffered_scores = function() {
    $.each(buffers, function(id, data) {
      console.log(id + ': ' + data.score_a + ' ' + data.score_b);
    })
  }

  var load_gui = function(id, _dir) {
    var dir = _dir == -1 ? 'left' : 'right';

    var animate_text = function(obj, text) {
      var span = obj.find('div');
      var new_span_raw = '<div data-new="true" style="display:none">' + text + '<span>';
      var span_height = span.outerHeight();
      var anims = {
        in: 'animated ' + (dir == 'left' ? 'fadeInLeft' : 'fadeInRight'),
        out: 'animated ' + (dir == 'right' ? 'fadeOutLeft' : 'fadeOutRight')
      }

      span.addClass(anims.out);

      obj.append(new_span_raw);
      var new_span = obj.find('div[data-new]');
      setTimeout(function() {
        new_span
          .show()
          .css('position', 'relative')
          .css('top', (-1 * span_height) + 'px');
        new_span.addClass(anims.in);

        new_span.one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
          span.remove();
          new_span
            .removeAttr('data-new')
            .removeClass(anims.in)
            .css('top', 0);
        })
      }, 0)  
    }

    var animate_image = function(obj) {
      var old_image = $('#img-container').find('img:visible');
      var anims = {
        in: 'animated ' + (dir == 'left' ? 'fadeInLeft' : 'fadeInRight'),
        out: 'animated ' + (dir == 'right' ? 'fadeOutLeft' : 'fadeOutRight')
      }
      var get_top_amount = function() {
        if (dir == 'right') {
          return (-1 * Math.min(old_image.height(), $('#img-container').height())) + 'px';
        } 

        return 0;
      }
      var get_reverse_top_amount = function() {
        if (dir == 'left') {
          return (-1 * Math.min(obj.height(), $('#img-container').height())) + 'px';
        }
          
        return 0;
      }


      old_image
        .css('position', 'relative')
        .css('top', get_reverse_top_amount())
        .removeClass(anims.in);

      old_image.addClass(anims.out)
      old_image.one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
        $(this)
          .hide()
          .removeClass(anims.out)
          .css('top', 0)

      })

      obj
        .show()
        .css('position', 'relative')
        .css('top', get_top_amount())
        .css('max-height', ($('#img-container').outerHeight() - 16) + 'px')

      obj.addClass(anims.in);
      obj.one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function() {
        $(this)
          .removeClass(anims.in)
          .css('top', 0)
        disable_buttons(false);
      })
    }

    var update_sentences = function() {
      animate_text($('#sentence-a-container'), buffers[id].s_a);
      animate_text($('#sentence-b-container'), buffers[id].s_b);
    }

    var update_scores = function() {
      var d = buffers[id];

      slider_a.slider('setValue', d.score_a || 3);
      slider_b.slider('setValue', d.score_b || 3);
    }

    disable_buttons(true);
    animate_image($('#img-' + id));
    update_sentences();
    update_scores();
    gui_position = id;
    buffer_position = id;
    fetch_buffered();
  }

  var update_gui = function(id) {
    var make_image = function() {
      var img_path = '/assets/' + buffers[id].picture_name;
      var s = '<img id="img-' + id + '" class="img-box" '
            +   'src="' + img_path + '" '
            +   'style="display:none" '
            + '/>'

      $('#img-container').append(s);
    }

    make_image();
    if (gui_position < 0) load_gui(0);
  }

  return {
    attach: attach,
    get_buffers: function() { return buffers; },
    get_buffered_scores: get_buffered_scores,
  }
}()