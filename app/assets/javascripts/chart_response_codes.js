function chart_response_codes(){
  $('#chart_response_codes').empty();
  $('#table_response_codes_by_code').empty();
  var testguid = getParameterByName('testguid');
  var interval = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  new Rickshaw.Graph.Ajax( {
    element: document.getElementById("chart_response_codes"),
    height: 150,
    width: $('.page-header').width(),
    renderer: 'line',
    stroke: true,
    dataURL: '/charts/get_response_codes?testguid='+testguid+'&interval='+interval+'&tags=jmeter'+'&label=' + ( $('#filter').val() ? $('#filter').val() : ''),
    onData: function(d) { 
      $('#table_response_codes_by_code').append('<table id="table_response_codes" class="table table-condensed table-striped span6"><thead><tr>' +
        '<th>Response Code</th>' +
        '<th>Count</th>' +
        '<th>Trans/sec</th>' +
        '</tr></thead><tbody></tbody></table>');
      $.each(d, function(key, val) {
        $('#table_response_codes  > tbody:last').append('<tr>' +
          '<td>' + val.name + '</td>' + 
          '<td>' + addCommas(val.stats.count.toFixed(0)) + '</td>' + 
          '<td>' + addCommas(val.stats.tps.toFixed(2)) + '</td>' + 
          '</tr>');
      });   
      Rickshaw.Series.zeroFill(d); 
      return d;
    },
    onComplete: function(transport) {
      var graph = transport.graph;
      var hoverDetail = new Rickshaw.Graph.HoverDetail( {
        graph: graph,
        yFormatter: function(y) { return Math.floor(y) }
      } );
      var yAxis = new Rickshaw.Graph.Axis.Y({ graph: graph });
      yAxis.render();
      var slider = new Rickshaw.Graph.RangeSlider( {
        graph: graph,
        element: $('#slide_response_codes')
      } );
    }
  } );
}