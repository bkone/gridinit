function chart_response_times() {
  $('#chart_response_times > div.chart').empty();
  var interval  = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  var satisfied = getParameterByName('satisfied') ? getParameterByName('satisfied') : 4000;
  var testguid  = getParameterByName('testguid');
  new Rickshaw.Graph.Ajax( {
    element: document.querySelector('#chart_response_times > div.chart'),
    height: 150,
    width: $('.page-header').width(),
    renderer: 'line',
    interpolation: 'cardinal',
    dataURL: '/charts/get_response_times?testguid='+testguid+'&satisfied='+satisfied+'&interval='+interval+'&tags=jmeter'+'&label=' + ( $('#filter').val() ? $('#filter').val() : '') ,
    onData: function(d) { 

      $('#stats_response_times > a.min').append('<sub>RESPONSE TIME</sub><span class="number">' + number_to_secs(d[0].stats.min) + '</span><span><sup>Minimum</sup></span>');
      $('#stats_response_times > a.max').append('<sub>RESPONSE TIME</sub><span class="number">' + number_to_secs(d[0].stats.max) + '</span><span><sup>Maximum</sup></span>');
      $('#stats_response_times > a.mean').append('<sub>RESPONSE TIME</sub><span class="number">' + number_to_secs(d[0].stats.mean) + '</span><span><sup>Average</sup></span>');
      $('#stats_response_times > a.sdev').append('<sub>RESPONSE TIME</sub><span class="number">' + number_to_secs(d[0].stats.std_deviation) + '</span><span><sup>Standard Deviation</sup></span>');
      $('#stats_generic > a.apdex').append('<sub>APDEX</sub><span class="number">' + d[0].apdex.stat + '</span><span><sup>' + capitalize(d[0].apdex.rating) + '</sup></span>');
      $('#stats_generic > a.failed').append('<sub>ERRORS</sub><span class="number">' + d[0].stats.failed + '</span><span><sup>Failed Transactions</sup></span>');  
      $('#stats_generic > a.failedpersec').append('<sub>ERRORS</sub><span class="number">' + addCommas(d[0].stats.fps.toFixed(2)) + '</span><span><sup>Failed Transaction/sec</sup></span>');  

      Rickshaw.Series.zeroFill(d); 
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
        element: document.querySelector('#chart_response_times > div.range-slider')
      } );
      var smoother = new Rickshaw.Graph.Smoother( {
        graph: graph,
        element: document.querySelector('#chart_response_times > div.smoother')
      } );
    }
  } );
}