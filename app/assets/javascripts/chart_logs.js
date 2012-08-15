function chart_logs() {
  var testguid = getParameterByName('testguid');
  var log_rows = [];
  $.ajax({
    url: 'logs/get_logs_by_message?testguid=' + testguid +
         '&scroll_id=0' +
         '&filter=' + $('#filter').val(),
    dataType: 'json',
    success: function (d) {
      $.each(d, function(key, val) {
        log_rows.push( HtmlEncode(val['@message']) );
      });
      $('.logs').html(log_rows.join('\n'));
      $('.logs').attr('data-scroll_id', $('#logs').attr('data-scroll_id') + 50 );
      prettyPrint();
    }
  });
}