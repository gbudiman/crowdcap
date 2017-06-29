var evals = function() {
  var potential_id = null;

  var fetch = function() {
    layout.enable_response(false);

    $.ajax({
      method: 'GET',
      url: '/evals/fetch'
    }).done(function(res) {
      if (res.response == 'success') {
        fetch_image('query', res.pquery);
        fetch_image('target', res.ptarget);
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

  return {
    fetch: fetch,
    post: post
  }
}()