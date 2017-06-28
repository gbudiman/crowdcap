var layout = function() {
  var attach = function() {
    $('.btn-response').show();
    enable_response(false);
    $(window).resize(recalculate_layout);

    recalculate_layout();
    attach_response_triggers();
  }

  var attach_response_triggers = function() {
    $('#response-bad').on('click', function() { evals.post('bad') });
    $('#response-good').on('click', function() { evals.post('good') });
  }

  var enable_response = function(val) {
    $('.btn-response').prop('disabled', !val);
  }

  var recalculate_layout = function() {
    var height = $(window).height();
    var viewport_width = $('.image-viewport').width();
    var viewport_height = 0.4 * height;
    var response_height = 0.2 * height;

    $('.image-viewport').css('height', viewport_height + 'px');
    $('.image-img')
      .css('max-height', viewport_height + 'px')
      .css('max-width', viewport_width + 'px');
  }


  return {
    attach: attach,
    enable_response: enable_response
  }
}()

