function chart_throughput(){
  $('#chart_throughput > div.chart').empty();
  var interval = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  var testguid = getParameterByName('testguid');
  new Rickshaw.Graph.Ajax( {
    element: document.querySelector('#chart_throughput > div.chart'),
    height: 150,
    width: $('.page-header').width(),
    renderer: 'line',
    interpolation: 'cardinal',
    dataURL: '/charts/get_throughput?testguid='+testguid+'&interval='+interval+'&tags=jmeter'+'&label=' + ( $('#filter').val() ? $('#filter').val() : ''),
    onData: function(d) { 

      $('#stats_throughput > a.min').append('<sub>THROUGHPUT</sub><span class="number">' + number_to_bps(d[0].stats.min) + '</span><span><sup>Minimum</sup></span>');
      $('#stats_throughput > a.max').append('<sub>THROUGHPUT</sub><span class="number">' + number_to_bps(d[0].stats.max) + '</span><span><sup>Maximum</sup></span>');
      $('#stats_throughput > a.mean').append('<sub>THROUGHPUT</sub><span class="number">' + number_to_bps(d[0].stats.mean) + '</span><span><sup>Average</sup></span>');
      $('#stats_throughput > a.sdev').append('<sub>THROUGHPUT</sub><span class="number">' + number_to_bps(d[0].stats.std_deviation) + '</span><span><sup>Standard Deviation</sup></span>');
      $('#stats_throughput > a.total').append('<sub>THROUGHPUT</sub><span class="number">' + number_to_human_size(d[0].stats.total) + '</span><span><sup>Sum Total</sup></span>');
      $('#stats_throughput > a.tps').append('<sub>THROUGHPUT</sub><span class="number">' + addCommas(d[0].stats.tps.toFixed(2)) + '</span><span><sup>Requests per second</sup></span>');

      Rickshaw.Series.zeroFill(d); 
      return d 
    },
    onComplete: function(transport) {
      var graph = transport.graph;
      var hoverDetail = new Rickshaw.Graph.HoverDetail( {
        graph: graph,
        yFormatter: function(y) { return number_to_human_size(Math.floor(y)) }
      } );
      var xAxis = new Rickshaw.Graph.Axis.Time({ graph: graph });
      xAxis.render();
      var yAxis = new Rickshaw.Graph.Axis.Y({ graph: graph });
      yAxis.render();
      var slider = new Rickshaw.Graph.RangeSlider( {
        graph: graph,
        element: document.querySelector('#chart_throughput > div.range-slider')
      } );
      var smoother = new Rickshaw.Graph.Smoother( {
        graph: graph,
        element:document.querySelector('#chart_throughput > div.smoother')
      } );
    }
  } );
}