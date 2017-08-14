var valmon = function() {
  var fetch_more_index = 0;
  var is_fetching_more = false;
  var end_of_db_records = false;
  var fetch_more_timeout = setTimeout(null, 0);

  var attach = function() {
    attach_table_refresh();
    attach_table_autoscroll();
    attach_resize_layout();
    //hide_stale_notification(true);
  }

  var attach_resize_layout = function() {
    $(window).resize(function() {
      layout.recalculate_tally_layout();
    })
  }

  var attach_table_autoscroll = function() {
    $('#table-container').scroll(is_at_end);
  }

  var attach_table_refresh = function() {
    $('#table-refresh').on('click', function(event) {
      refresh_table();

      event.preventDefault();
    })

    $('#tally-table-auto-update').change(function() {
      if ($(this).prop('checked')) {
        refresh_table();
      }
    })
  }

  var hide_stale_notification = function(val) {
    if (val) {
      $('#stale-notification').animate({
        opacity: 0
      }, 250, function() {
        $('#stale-notification').hide();
        layout.recalculate_tally_layout();
      })
    } else {
      $('#stale-notification').show().css('opacity', 0).animate({
        opacity: 1
      }, 250);

      layout.recalculate_tally_layout();
    }
  }

  var update = function(d) {
    if (d != null) {
      update_leaderboard(d);
    } else {
      format_dmos();
      refresh_table();
    }
  }

  var format_dmos = function() {
    var t = $('#tally-dmos').text();
    $('#tally-dmos').css('color', t.match(/\+/) ? 'green' : 'red')
  }

  var make_rows = function(res) {
    var t = '';
    $.each(res, function(i, r) {
      var date = moment(r.timestamped).format('YYYY-MM-DD HH:mm:ss')
      t += '<tr>'
        +    '<td style="width: 20%">' + date + '</td>'
        +    '<td style="width: 25%">' + r.sentence_a + '</td>'
        +    '<td style="width: 5%" class="tally-numeric">' + r.score_a + '</td>'
        +    '<td style="width: 5%" class="tally-numeric">' + r.score_dmos + '</td>'
        +    '<td style="width: 5%" class="tally-numeric">' + r.score_b + '</td>'
        +    '<td style="width: 25%">' + r.sentence_b + '</td>'
        +    '<td style="width: 15%" class="tally-numeric">'
        +      '<a href="#" class="subval-image-link" '
        +        'data-path="' + r.picture + '" '
        +      '</a>'
        +      r.picture_coco_id
        +    '</td>'
        +  '</tr>';
    });

    return t
  }

  var refresh_table = function() {
    var tbody = $('#table-denorm').find('tbody');

    tbody.animate({
      opacity: 0.3
    }, 250);

    $.ajax({
      url: '/subjective/evals/denorm',
      method: 'GET'
    }).done(function(res) {
      var t = make_rows(res);
      t += '<tr id="tally-end">'
        +    '<td colspan=7>End of records</td>'
        +  '</tr>';

      tbody.empty();
      tbody.append(t);
      subvals.activate_link();
      tbody.animate({
        opacity: 1
      }, 250);
      mark_stale(false);
      is_at_end();
      $('.popover').remove();
    })
  }

  var is_auto_update = function() {
    return $('#tally-table-auto-update').prop('checked');
  }

  var mark_stale = function(val) {
    hide_stale_notification(!val);
  }

  var update_leaderboard = function(d) {
    $('.tally-ldb').css('opacity', 0.5);

    $('#tally-mos-a').text(mos_format(d.mos_a));
    $('#tally-mos-b').text(mos_format(d.mos_b));
    $('#tally-dmos').text(mos_format(d.dmos, ['with_leading_sign']));
    $('#tally-count').text(d.count);

    format_dmos();

    if (is_auto_update()) {
      refresh_table();
    } else {
      mark_stale(true);
    }

    $('.tally-ldb').animate({
      opacity: 1
    }, 250);
  }

  var mos_format = function(x, _opts) {
    var opts = _opts == undefined ? [] : _opts;
    var with_leading_sign = opts.indexOf('with_leading_sign') != -1;
    if (with_leading_sign) {
      return $.sprintf('%+.2f', x);
    }

    return $.sprintf('%.2f', x);
  }

  var is_at_end = function() {
    var container_pos = $('body').outerHeight();
    var anchor_pos = $('#tally-end').offset().top;

    if (anchor_pos < container_pos) {
      fetch_more();
    }
  }

  var fetch_more = function() {
    if (is_fetching_more || end_of_db_records) return;

    clearTimeout(fetch_more_timeout);
    $('#tally-end').find('td').text('Fetching more rows...');
    is_fetching_more = true;

    fetch_more_timeout = setTimeout(function() {
      console.log('launching fetch more query');
      
      $.ajax({
        url: '/subjective/evals/denorm',
        data: {
          index_offset: ++fetch_more_index
        }
      }).done(function(res) {
        if (res.length == 0) {
          end_of_db_records = true;
          console.log('Server responded no more rows');
        } else {

          var t = make_rows(res);

          var anchor = $('#tally-end');
          anchor.before(t);
          is_fetching_more = false;
          $('#tally-end').find('td').text('End of records');
          subvals.activate_link();
        }
      }); 
    }, 250)
    
  }

  return {
    attach: attach,
    is_at_end: is_at_end,
    update: update
  }
}()