var cluster_maker = function() {
  var clear_cluster = function() {
    $('#cluster-master').empty();
  }

  var display = function() {
    clear_cluster();
    $.ajax({
      url: '/domains/fetch/cluster'
    }).done(function(res) {
      organize_gui(res);
    })
  }

  var organize_gui = function(ds) {
    var m = '';
    $.each(ds, function(k, imgs) {
      //m += '<div class="col-xs-12 col-sm-6 col-md-4 col-lg-3 cluster-group">';
      m += '<div class="panel panel-primary cluster-group">';
      m +=   '<div class="panel-heading text-center">Cluster ' + k + '</div>';
      m +=   '<div class="panel-body">'
      $.each(imgs, function(_junk, img_src) {
        m +=   '<div class="col-xs-6 col-sm-4 col-md-3 col-lg-2 cluster-cell-container">';
        m +=     '<img class="cluster-cell" src="/assets/thumb_' + img_src.picture_name + '" />';
        m +=   '</div>';
      })
      m +=   '</div>';
      m += '</div>';
    })

    $('#cluster-master').append(m);
  }

  return {
    display: display
  }
}()

$(function() {
  cluster_maker.display();
})