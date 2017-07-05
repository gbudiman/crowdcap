var evals = function() {
  var query_ready = false;
  var target_ready = false;
  var buffer = new Array();
  var buffer_position = 0;
  var buffer_end = 0;
  var batch_fetch = 8;
  var buffer_minimum = 4;
  var potential_h = {};
  var objects = {};

  var attach = function() {
    $('#eval-begin').prop('disabled', true).text('Prefetching images...');
    $('#eval-begin').on('click', begin_test);
    $('#image-query-img').load(function() {
      set_ready('query');
    })
    $('#image-target-img').load(function() {
      set_ready('target');
    })
    buffer_fetch(false);
    layout.enable_response(true);
  }

  var buffer_fetch = function(_pop) {
    var diff = buffer_end - buffer_position;
    if (diff < buffer_minimum) {
      var fetch_amount = batch_fetch - diff;

      console.log('Buffer amount = ' + diff + ', fetching ' + fetch_amount + ' more');

      for (var i = 0; i < fetch_amount; i++) {
        fetch_in_background(buffer_end + i);
      }
    }
    
    if (_pop) {
      console.log('Buffer position = ' + buffer_position + '/' + buffer_end);
      pop_and_display_buffer();
    }
  }

  var pop_and_display_buffer = function() {
    var buffered_query = $('#query_' + buffer_position).css('opacity', 0).css('display', 'block');
    var buffered_target = $('#target_' + buffer_position).css('opacity', 0).css('display', 'block');

    $('#image-query').empty().append(buffered_query);
    $('#image-target').empty().append(buffered_target);

    buffered_query.animate({
      opacity: 1.0
    }, 250);

    buffered_target.animate({
      opacity: 1.0
    }, 250);
    update_objects(objects[buffer_position]);
    layout.recalculate_layout();
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

  var fetch_in_background = function(id) {
    console.log('fetching for buffer position ' + id);
    $.ajax({
      method: 'GET',
      url: '/evals/fetch'
    }).done(function(res) {
      if (res.response == 'success') {
        create_hidden_div('query', res.pquery, id);
        create_hidden_div('target', res.ptarget, id);
        potential_h[id] = res.id;
        objects[id] = res.objects;
        buffer_end++;

        if (buffer_end >= batch_fetch) {
          $('#eval-begin').prop('disabled', false).text('Begin');
        }
      }
    })
  }

  var create_hidden_div = function(type, _name, _buffer_id) {
    var name = '/assets/' + _name;
    var raw = '';
    var element_name = '';
    var buffer_id = '';

    switch(type) {
      case 'query': 
        element_name = 'image-query-img';
        buffer_id = 'query_' + _buffer_id; 
        break;
      case 'target': 
        element_name = 'image-target-img';
        buffer_id = 'target_' + _buffer_id; break;
    }

    raw = '<img name="' + element_name + '" '
             + 'id="' + buffer_id + '" '
             + 'class="image-img center-block image-infancy" '
             + 'src="' + name + '">';
    $('body').append(raw);
  }

  var fetch_image = function(type, _name) {
    var name = '/assets/' + _name;
    switch(type) {
      case 'query': $('[name="image-query-img"]').attr('src', name); break;
      case 'target': $('[name=image-target-img"]').attr('src', name); break;
    }
  }

  var post = function(val) {
    //layout.enable_response(false);
    var potential_id = potential_h[buffer_position];
    buffer_position++;
    $.ajax({
      method: 'POST',
      url: '/evals/post',
      data: {
        val: val,
        id: potential_id
      }
    }).done(function(res) {
      if (res.response == 'success') {
        //fetch();
        buffer_fetch(true);
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
      $('#eval-intro').remove();
      layout.recalculate_layout();
      buffer_fetch(true);
    })
    
  }

  return {
    attach: attach,
    fetch: fetch,
    post: post,
    get_potentials: function() { return potential_h; },
    get_objects: function() { return objects; }
  }
}()