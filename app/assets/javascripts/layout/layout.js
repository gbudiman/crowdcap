var layout = function() {
  var attach = function() {
    $('.btn-response').show();
    enable_response(false);
    $(window).resize(recalculate_layout);

    recalculate_layout();
    attach_response_triggers();
  }

  var attach_to_subjective_evals = function() {
    $(window).resize(recalculate_subval_layout);
    recalculate_subval_layout();
  }

  var recalculate_subval_layout = function() {
    var height = $(window).height();
    var width = $(window).width()
    var img_height = 0.6 * height;
    var sentence_height = 0.3 * height;
    var response_height = 0.1 * height;
    var button_width = width / 5;

    $('#img-container').css('height', img_height + 'px');
    $('#sentence-a-container').css('height', sentence_height + 'px');
    $('#sentence-b-container').css('height', sentence_height + 'px');
    $('.slider-container').css('height', sentence_height + 'px');
    $('#mos-a-slider').css('height', (sentence_height - 32) + 'px');
    $('#mos-b-slider').css('height', (sentence_height - 32) + 'px');
    $('#response-container').css('height', response_height + 'px');
    $('.btn-resp')
      .css('height', (response_height - 16) + 'px')
      .css('width', (button_width - 16) + 'px')
    $('.img-box')
      .css('max-height', (img_height - 16) + 'px')
      .css('max-width', (width - 16) + 'px')
    $('body')
      .css('overflow-x', 'hidden')
      .css('overflow-y', 'hidden');
    $('.modal').css('width', width - 16);
    $('.modal').css('margin', '8px');
  }

  var attach_response_triggers = function() {
    $('#response-bad').on('click', function() { evals.post('bad') });
    $('#response-good').on('click', function() { evals.post('good') });
  }

  var enable_response = function(val) {
    $('.btn-response').prop('disabled', !val);
  }

  var recalculate_layout = function() {
    var height = $(window).height() - $('#detected-objects-container').outerHeight() - 16;
    var viewport_width = $('.image-viewport').width();
    var viewport_height = 0.4 * height;
    var response_height = 0.2 * height;

    $('.image-viewport').css('height', viewport_height + 'px');
    $('.image-img')
      .css('max-height', viewport_height + 'px')
      .css('max-width', viewport_width + 'px');
  }

  var recalculate_tally_layout = function() {
    var height = $(window).height()
               - $('#leaderboard').outerHeight()
               - $('#tooling').outerHeight()
               - $('#fake-table-header').outerHeight()
               + 21;

    $('#table-container').css('height', height + 'px');
  }

  // var recalculate_result_table_layout = function() {
  //   var modal = $('#result-modal');
  //   var height = $(window).height()
  //              - modal.find('.modal-header').height()
  //              - modal.find('.modal-footer').height()
  //              - modal.find('#method-info').height();

  //   $('#result-table-container')
  //     .css('max-height', height + 'px')
  //     .css('overflow-y', 'auto');
  // }


  return {
    attach: attach,
    attach_to_subjective_evals: attach_to_subjective_evals,
    enable_response: enable_response,
    recalculate_layout: recalculate_layout,
    recalculate_tally_layout: recalculate_tally_layout,
  }
}()

