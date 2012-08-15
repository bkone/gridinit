$(function(){
  $.ajaxSetup({
    beforeSend: function(xhr) {
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    }
  });

  $("img[rel=tooltip]").tooltip();
  $("span[rel=tooltip]").tooltip();
  $("i[rel=tooltip]").tooltip();
  $("input[rel=tooltip]").tooltip();

  $('.compare').click(function(e) {
    e.preventDefault();
    // console.log($(this));
    // console.log($('input#runs:checked'));
    alert("This feature is coming soon");
  });

  $('input#checkallnodes').click(function() {
    $('input:checkbox:not(:disabled)').attr('checked', this.checked);
  });

  $('ul#interval li > a').click(function(e) {
    e.preventDefault();
    window.location.href = $.param.querystring(window.location.href, 
      $(this).attr('data-param')+'='+$(this).attr('data-value'));
  });

  $('ul#chart li > a').click(function(e) {
    $('.chart-container.active').toggle().removeClass('active');
    $('#'+$(this).attr('data-value')).toggle().addClass('active');
    $('.chart-label').html($(this).text());
    e.preventDefault();
  });

  $('div.chart-container:not(.active)').hide();

  $('a.stat-column:not(.active)').hide();
  $('a.stat-column').click(function(e) {
    $(this).toggle().removeClass('active');
    if($(this).next().length == 0) {
      $(this).parent().children('a:first').addClass('active').toggle();
    } else { 
      $(this).next().addClass('active').toggle();
    }
  });

  $('div.roles:not(.active)').hide();
  
  $('ul#roles li > a').click(function(e) {
    var role = $(this).parent().attr('data-role');
    console.log(role);
    $('div.roles.active').toggle().removeClass('active');
    $('div.' + role).toggle().addClass('active');
    $('ul#roles li.active').removeClass('active');
    $(this).parent().addClass('active');
    $('input#role').val(role);
  });

  $('.btn-nodeconfig').click(function(e) {
    e.preventDefault();
    
    $("#form-nodeconfig").attr("action","http://" + 
      $("#host").val() +
      ":" + window.document.location.port +
      "/nodes/"+$("#host").val());

    $('#form-nodeconfig').submit();
  });

  $(".node-role").click(function(){
    $("#host").val($(this).data('host'));
    $("input#role").val($(this).data('role'));

    var role = $(this).data('role');
    $('div.roles.active').toggle().removeClass('active');
    $('div.' + role).toggle().addClass('active');
    $('ul#roles li.active').removeClass('active');
    $('ul#roles li[data-role="'+role+'"]').addClass('active')
    $('div.roles:not(.active)').hide();
  });

  $('#basic > a').click(function(){
    $('.basic').show('fast');
    $('.advanced').hide('fast');
    $('#basic').addClass('active');
    $('#advanced').removeClass('active');
  });

  $('#advanced > a').click(function(){
    $('.basic').hide('fast');
    $('.advanced').show('fast');
    $('#basic').removeClass('active');
    $('#advanced').addClass('active');
  });

  $('#runtest').click(function(e){
    e.preventDefault();
    if($('.basic').is(":visible")) { 
      $('#form-basic').submit();    
    }
    if($('.advanced').is(":visible")) { 
      $('#form-advanced').submit();
    } 
  });

  $(".notes").editable("/runs/notes", {
    name : 'notes',
    cssclass : 'input-small',
    data: function(value, settings) {
      var retval = value.replace(/.*/gi, '');
      return retval;
    }
  });

  $("#form-advanced").validate({
    rules: {
      attachment: {
        required: true
      },
      "nodes[]": { 
        required: true, 
        minlength: 1 
      }
    },
    messages: { 
      "nodes[]": "Please select at least one grid node."
    } 
  });

  $('#runs-filter').typeahead().on('keyup', function(ev){
    ev.stopPropagation();
    ev.preventDefault();
    //filter out up/down, tab, enter, and escape keys
    if( $.inArray(ev.keyCode,[40,38,9,13,27]) === -1 ){
      var self = $(this);
      //set typeahead source to empty
      self.data('typeahead').source = [];
      //active used so we aren't triggering duplicate keyup events
      if( !self.data('active') && self.val().length > 0){
        self.data('active', true);
        //Do data request. Insert your own API logic here.
        var run_terms = [];
        $.ajax({
          url: 'runs',
          async: false,
          dataType: 'json',
          success: function (data) {
            $.each(data, function(key, val) {
              run_terms.push( val );
            });
            self.data('typeahead').source = run_terms;
            //trigger keyup on the typeahead to make it search
            self.trigger('keyup');
            //All done, set to false to prepare for the next remote query.
            self.data('active', false);
          }
        });          
      }
    }
  });

  if (location.hash !== '') $('a[href="' + location.hash + '"]').tab('show');
  return $('a[data-toggle="tab"]').on('shown', function(e) {
    return location.hash = $(e.target).attr('href').substr(1);
  });
});