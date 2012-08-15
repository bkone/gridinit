function chart_errors_by_label(){
  $('#chart_errors_by_label > div.chart').empty();
  $('#chart_errors_by_label > div.legend').empty();
  var interval  = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  var satisfied = getParameterByName('satisfied') ? getParameterByName('satisfied') : '4000';
  var testguid  = getParameterByName('testguid');
  new Rickshaw.Graph.Ajax( {
    element: document.querySelector('#chart_errors_by_label > div.chart'),
    height: 150,
    width: $('.page-header').width(),
    renderer: 'line',
    interpolation: 'cardinal',
    dataURL: '/charts/get_errors_by_label?testguid='+testguid+''+
    '&interval='+interval+
    '&tags=errors'+
    '&satisfied='+satisfied+
    '&label=' + ( $('#filter').val() ? $('#filter').val() : ''),
    onData: function(d) { 
        $('#chart_errors_by_label > div.legend').append('<table class="table table-condensed"><thead><tr>' +
        '<th>Error Details</th>' +
        '<th>Count</th>' +
        '<th>Errors/sec</th>' +
        '</tr></thead><tbody></tbody></table>');
      $.each(d, function(key, val) {
        $('#chart_errors_by_label > div.legend > table > tbody:last').append('<tr>' +
          '<td title="' + val.alt + '">' + val.name + '</td>' + 
          '<td>' + addCommas(val.stats.count.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.tps.toFixed(2)) + '</td>' + 
          '</tr>');
      });   

      Rickshaw.Series.lastFill(d); 
      return d 
    },
    onComplete: function(transport) {
      var graph = transport.graph;
      var hoverDetail = new Rickshaw.Graph.HoverDetail( {
        graph: graph,
        yFormatter: function(y) { return Math.floor(y) + " errors" }
      } );
      var xAxis = new Rickshaw.Graph.Axis.Time({ graph: graph });
      xAxis.render();
      var yAxis = new Rickshaw.Graph.Axis.Y({ graph: graph });
      yAxis.render();
      var slider = new Rickshaw.Graph.RangeSlider( {
        graph: graph,
        element: $('#chart_errors_by_label > div.range-slider')
      } );
      var smoother = new Rickshaw.Graph.Smoother( {
        graph: graph,
        element: $('#chart_errors_by_label > div.smoother')
      } );
      $.tablesorter.addParser({
        id: 'fancyNumber',
        is:function(s){return false;},
        format: function(s) {return s.replace(/[\,\.]/g,'');},
        type: 'numeric'
      });
      $("#chart_errors_by_label > div.legend > table").tablesorter({headers: {0: {sorter: 'fancyNumber'}}});
      var annotator = new Rickshaw.Graph.Annotate( {
        graph: graph,
        element: document.querySelector('#chart_errors_by_label > div.annotations')
      });
      var request = $.ajax({
        url: '/errors/get_snapshots?testguid='+testguid+'',
        dataType: 'json'
      });
      request.done(function(d) {
        $.each(d, function(key, val) {
          annotator.add(val.timestamp,val.message); 
        });
        graph.update();
        $('.annotation').hover(function(){
          $(this).find('img').attr('src',$(this).find('img').data('png')).css('width', 260);
           $(this).find('img').fadeIn(2000);
        });
      });
    }
  } );
}