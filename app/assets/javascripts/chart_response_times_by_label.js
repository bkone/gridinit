function chart_response_times_by_label(){
  $('#chart_response_times_by_label > div.chart').empty();
  $('#chart_response_times_by_label > div.legend').empty();
  var interval  = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  var satisfied = getParameterByName('satisfied') ? getParameterByName('satisfied') : '4000';
  var testguid  = getParameterByName('testguid');
  new Rickshaw.Graph.Ajax( {
    element: document.querySelector('#chart_response_times_by_label > div.chart'),
    height: 150,
    renderer: 'line',
    interpolation: 'cardinal',
    dataURL: '/charts/get_response_times_by_label?testguid='+testguid+''+
    '&interval='+interval+
    '&tags=jmeter'+
    '&satisfied='+satisfied+
    '&label=' + ( $('#filter').val() ? $('#filter').val() : ''),
    onData: function(d) { 
            $('#chart_response_times_by_label > div.legend').append('<table class="table table-condensed"><thead><tr>' +
        '<th>Label</th>' +
        '<th>Apdex&nbsp;</th>' +
        '<th>Mean</th>' +
        '<th>SDev</th>' +
        '<th>Count</th>' +
        '<th>Passed</th>' +
        '<th>Failed</th>' +
        '<th>Min</th>' +
        '<th>Max</th>' +
        '<th>Trans/sec</th>' +
        '<th>Last</th>' +
        '</tr></thead><tbody></tbody></table>');
      $.each(d, function(key, val) {
        $('#chart_response_times_by_label > div.legend > table > tbody:last').append('<tr>' +
          '<td style="width:100%;background-color:'+ val.apdex.colour +'" title="Apdex: ' + val.apdex.print + '">' + val.name + '</td>' + 
          '<td>' + addCommas(val.apdex.stat) + '</td>' + 
          '<td>' + addCommas(val.stats.mean.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.std_deviation.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.count.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.passed.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.failed.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.min.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.max.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.tps.toFixed(2)) + '</td>' + 
          '<td>' + addCommas(val.stats.last.toFixed(0)) + '</td>' + 
          '</tr>');
      });   

      Rickshaw.Series.lastFill(d); 
      return d 
    },
    onComplete: function(transport) {
      var graph = transport.graph;
      var hoverDetail = new Rickshaw.Graph.HoverDetail( {
        graph: graph,
        yFormatter: function(y) { return Math.floor(y) + " msecs" }
      } );
      var xAxis = new Rickshaw.Graph.Axis.Time({ graph: graph });
      xAxis.render();
      var yAxis = new Rickshaw.Graph.Axis.Y({ graph: graph });
      yAxis.render();
      var slider = new Rickshaw.Graph.RangeSlider( {
        graph: graph,
        element: $('#chart_response_times_by_label > div.range-slider')
      } );
      var smoother = new Rickshaw.Graph.Smoother( {
        graph: graph,
        element: $('#chart_response_times_by_label > div.smoother')
      } );
      $("#chart_response_times_by_label > div.legend > table").tablesorter({headers: {0: {sorter: 'fancyNumber'}}});
      var annotator = new Rickshaw.Graph.Annotate( {
        graph: graph,
        element: document.querySelector('#chart_response_times_by_label > div.annotations')
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