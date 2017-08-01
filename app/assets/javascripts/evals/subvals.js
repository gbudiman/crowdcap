var subvals = function() {
  var state = 'init';
  var data = {
    buffered: { id_a: null, id_b: null, s_a: null, s_b: null, is_swapped: false },
    main:     { id_a: null, id_b: null, s_a: null, s_b: null, is_swapped: false }
  }

  var attach = function() {
    attach_responses();
    fetch('main').then((res) => {
      fetch('buffered').then((res) => {
        state = 'buffered';
        update_gui();
        state = 'main';
      })
    });
  }

  var attach_responses = function() {
    $('.btn-resp').on('click', function() {
      
      var container = data[flipped_state()];
      var raw_score = parseInt($(this).attr('data-val'));
      var score = raw_score * (container.is_swapped ? 1 : -1);
      var pdb = pack_debug_info(container);

      enable_response_buttons(false);
      give_feedback(true, raw_score);

      // console.log('state: ' + state);
      // console.log('[' + pdb.id_left + '] ' + pdb.box_left + ' | ' + 
      //             '[' + pdb.id_right + '] ' + pdb.box_right + ' => ' + score);
      $.ajax({
        url: '/subjective/evals/post',
        method: 'POST',
        data: {
          a_id: container.id_a,
          b_id: container.id_b,
          score: score
        }
      }).done(function() {
        update_gui();
        if (state == 'main') {
          state = 'buffered';
          fetch(state);
        } else {
          state = 'main';
          fetch(state);
        }
        
        enable_response_buttons(true);
      })
    })

    $('.btn-resp').each(function() {
      var $this = $(this);
      var val = parseInt($this.attr('data-val'));
      var text = '';

      switch (val) {
        case -2: text = 'Left sentence is substantially better'; break;
        case -1: text = 'Left sentence is marginally better'; break;
        case  0: text = 'Both sentence are subjectively equally good'; break;
        case  1: text = 'Right sentence is marginally better'; break;
        case  2: text = 'Right sentence is substantially better'; break;
      }

      $this.tooltip({
        placement: 'top',
        title: text,
        trigger: 'hover',
        viewport: '#response-container'
      })
    })
  }

  var enable_response_buttons = function(val) {
    $('.btn-resp').prop('disabled', !val);
  }

  var flipped_state = function() {
    if (state == 'main') return 'buffered';
    return 'main';
  }

  var fetch = function(state) {
    return new Promise((resolve, reject) => {
      $.ajax({
        url: '/subjective/evals/fetch'
      }).done(function(res) {
        update_backend(res, state)
        resolve(true);
      })
    });
  }

  var give_feedback = function(val, score) {
    if (val) {
      if (score == 0) {
        $('.sentence-container').css('opacity', 0.5);
        return;
      }

      var anchor = score < 0 ? $('#sentence-a-container') : $('#sentence-b-container');
      var other = score > 0 ? $('#sentence-a-container') : $('#sentence-b-container');
      
      anchor
        .css('background-image', "url('/assets/checkmark.png')");
      other
        .css('opacity', 0.5);
    } else {
      $('.sentence-container').css('opacity', 1).css('background-image', 'none');
    }
  }

  var pack_debug_info = function(c) {
    return {
      box_left: $('#sentence-a-container').text(),
      box_right: $('#sentence-b-container').text(),
      id_left: c.id_a,
      id_right: c.id_b
    }
  }

  var update_backend = function(res, state) {
    var container = data[state];
    var asset_path = '/assets/' + res.picture.name;
    container.is_swapped = Math.round(Math.random()) == 1 ? true : false;

    if (container.is_swapped) {
      container.s_a = res.methods['99'].text;
      container.s_b = res.methods['0'].text;

      container.id_a = res.methods['99'].id;
      container.id_b = res.methods['0'].id;
    } else {
      container.s_a = res.methods['0'].text;
      container.s_b = res.methods['99'].text;

      container.id_a = res.methods['0'].id;
      container.id_b = res.methods['99'].id;
    }

    if (state == 'main') {
      $('#img-main').attr('src', asset_path);
    } else {
      $('#img-buffered').attr('src', asset_path);
    }
  }

  var update_gui = function() {
    var cached_sentence = data[state];
    if (state == 'main') {
      $('#img-buffered').addClass('animated slideOutUp');
      $('#img-buffered').animate({
        opacity: 0
      }, 250, function() {
        $('#img-main').addClass('animated slideInUp');

        $('#img-buffered').hide();
        $('#img-main').show().animate({
          opacity: 1
        }, 250, function() {
          $('#img-buffered').removeClass('animated slideOutUp');
          update_sentence_box(cached_sentence);
        });
      })
    } else {
      $('#img-main').addClass('animated slideOutUp');
      $('#img-main').animate({
        opacity: 0
      }, 250, function() {
        $('#img-buffered').addClass('animated slideInUp');
        $('#img-main').hide();
        $('#img-buffered').show().animate({
          opacity: 1
        }, 250, function() {
          $('#img-main').removeClass('animated slideOutUp');
          update_sentence_box(cached_sentence);
        });
      })
    }

    //update_sentence_box(data[state]);
  }

  var update_sentence_box = function(d) {

    $('#sentence-a-container').text(d.s_a);
    $('#sentence-b-container').text(d.s_b);
    give_feedback(false);
  }

  return {
    attach: attach,
    fetch: fetch,
    get_data: function() { return data; },
    get_state: function() { return state; },
    is_swapped: function() { return data[state].is_swapped; }
  }
}()