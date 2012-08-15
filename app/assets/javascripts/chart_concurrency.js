function chart_concurrency(){
  $('#chart_concurrency > div.chart').empty();
  var testguid = getParameterByName('testguid');
  var interval = getParameterByName('interval') ? getParameterByName('interval') : 'second';
  new Rickshaw.Graph.Ajax( {
    element: document.querySelector('#chart_concurrency > div.chart'),
    height: 150,
    width: $('.page-header').width(),
    renderer: 'area',
    stroke: true,
    dataURL: '/charts/get_concurrency?testguid='+testguid+'&interval='+interval+'&tags=jmeter'+'&label=' + ( $('#filter').val() ? $('#filter').val() : ''),
    onData: function(d) { 
      var last=0;
      var max =0;
      var mean=0;
      $.each(d, function(key, val) {
        last += val.stats.last;
        max += val.stats.max;
        mean += val.stats.mean
      });

      $('#stats_concurrency > a.last').append('<sub>CONCURRENCY</sub><span class="number">' + addCommas(last.toFixed(0)) + '<sup>users</sup></span><span><sup>Last Active</sup></span>');
      $('#stats_concurrency > a.max').append('<sub>CONCURRENCY</sub><span class="number">' + addCommas(max.toFixed(0)) + '<sup>users</sup></span><span><sup>Maximum</sup></span>');
      $('#stats_concurrency > a.mean').append('<sub>CONCURRENCY</sub><span class="number">' + addCommas(mean.toFixed(0)) + '<sup>users</sup></span><span><sup>Average</sup></span>');

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
        element: document.querySelector('#chart_concurrency > div.range-slider')
      } );
    }
  } );
}