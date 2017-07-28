var subvals = function() {
  var id_a = null;
  var id_b = null;
  var is_swapped = false;

  var attach = function() {
    attach_responses();
    fetch();
  }

  var attach_responses = function() {
    $('.btn-resp').on('click', function() {
      enable_response_buttons(false);
      var score = parseInt($(this).attr('data-val')) * (is_swapped ? 1 : -1);
      $.ajax({
        url: '/subjective/evals/post',
        method: 'POST',
        data: {
          a_id: id_a,
          b_id: id_b,
          score: score
        }
      }).done(function() {
        fetch();
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
    $('.btn-resp').prop('disabled', !val)
  }

  var fetch = function() {
    $.ajax({
      url: '/subjective/evals/fetch'
    }).done(function(res) {
      update_gui(res)
    })
  }

  var update_gui = function(res) {
    is_swapped = Math.round(Math.random()) == 1 ? true : false;
    console.log(is_swapped);

    if (is_swapped) {
      var sentence_a = res.methods['99'].text;
      var sentence_b = res.methods['0'].text;

      id_a = res.methods['99'].id;
      id_b = res.methods['0'].id;
    } else {
      var sentence_a = res.methods['0'].text;
      var sentence_b = res.methods['99'].text;

      id_a = res.methods['0'].id;
      id_b = res.methods['99'].id;
    }

    $('#img-box').attr('src', '/assets/' + res.picture.name)
    $('#sentence-a-container').text(sentence_a);
    $('#sentence-b-container').text(sentence_b);
  }

  return {
    attach: attach,
    fetch: fetch,
    is_swapped: function() { return is_swapped; }
  }
}()