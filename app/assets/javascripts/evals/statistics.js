var statistics = function() {
  var bars;
  var dmos;

  var attach = function() {
    bars = $('.stats-bar');
    dmos = $('.stats-dmos');
    update_visual();
    attach_popup();
    $(window).on('resize', update_visual);
  }

  var update_visual = function() {
    var master_width = $('#stat-table').width() * 0.4 / 3;
    $('.stat-header').css('width', master_width + 'px');
    update_bars(master_width);
    update_dmos(master_width);
  }

  var update_bars = function(max) {
    $.each(bars, function() {
      var length = parseFloat($(this).attr('data-val')) / 5 * max;
      $(this).css('width', length + 'px')
    })
  }

  var update_dmos = function(max) {
    $.each(dmos, function() {
      var val = parseFloat($(this).attr('data-val')) / 10 * max;
      var absval = Math.abs(val);

      $(this).css('width', absval + 'px');
      if (val < 0) {
        $(this).css('margin-left', (max / 2 - absval) + 'px')
      } else {
        $(this).css('margin-left', max / 2 + 'px');
      }
    })
  }

  var attach_popup = function() {

    $('.cluster-cell').each(function() {
      var src = $(this).attr('src');
      $(this).popover({
        show: false,
        html: true,
        content: '<img src="' + src + '" />',
        trigger: 'hover',
        placement: 'bottom'
      })
    });
  }



  return {
    attach: attach
  }
}()

statistics.attach();