var evals = function() {
  var potential_id = null;

  var attach = function() {
    $('#eval-begin').on('click', begin_test);
    fetch();
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
        update_objects(res.objects);
        layout.enable_response(true);
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