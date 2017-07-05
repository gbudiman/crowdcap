var evals = function() {
  var potential_id = null;
  var query_ready = false;
  var target_ready = false;
  var buffer = new Array();
  var buffer_position = 0;
  var buffer_end = 0;
  var batch_fetch = 8;
  var buffer_minimum = 4;

  var attach = function() {
    $('#eval-begin').on('click', begin_test);
    $('#image-query-img').load(function() {
      set_ready('query');
    })
    $('#image-target-img').load(function() {
      set_ready('target');
    })
    buffer_fetch();
  }

  var buffer_fetch = function() {
    var diff = buffer_end - buffer_position;
    if (diff < buffer_minimum) {
      var fetch_amount = batch_fetch - diff;

      console.log('Buffer amount = ' + diff + ', fetching ' + fetch_amount + ' more');

    } else {
      console.log('Buffer amount = ' + diff);
    }
  }

  var evaluate_readiness = function() {
    if (query_ready && target_ready) {
      layout.enable_response(true);
    }
  }

  var fetch = function() {
    layout.enable_response(false);

    $.ajax({
      method: 'GET',
      url: '/evals/fetch'
    }).done(function(res) {
      if (res.response == 'success') {
        fetch_image('query', res.pquery);
        fetch_image('target', res.ptarget);
        reset_readiness();
        update_objects(res.objects);
        potential_id = res.id
      }
    })
  }

  var fetch_image = function(type, _name) {
    var name = '/assets/' + _name;
    switch(type) {
      case 'query': $('#image-query-img').attr('src', name); break;
      case 'target': $('#image-target-img').attr('src', name); break;
    }
  }

  var post = function(val) {
    layout.enable_response(false);
    $.ajax({
      method: 'POST',
      url: '/evals/post',
      data: {
        val: val,
        id: potential_id
      }
    }).done(function(res) {
      if (res.response == 'success') {
        fetch();
      }
    })
  }

  var set_ready = function(x) {
    switch (x) {
      case 'query': query_ready = true; break;
      case 'target': target_ready = true; break;
    }

    evaluate_readiness();
  }

  var reset_readiness = function() {
    query_ready = false;
    target_ready = false;
  }

  var update_objects = function(arr) {
    $('#detected-objects').text(arr.join(', '))
  }

  var begin_test = function() {
    $('#eval-intro').animate({
      opacity: 0
    }, 500, function() {
      $('#eval-intro').addClass('animated slideOutUp');
      $('#eval-interface').show().addClass('animated slideInUp');
      layout.recalculate_layout();
    })
    
  }

  return {
    attach: attach,
    fetch: fetch,
    post: post
  }
}()