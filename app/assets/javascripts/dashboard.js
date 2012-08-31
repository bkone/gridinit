$(function(){

  // CSRF TOKENS
  $.ajaxSetup({
    beforeSend: function(xhr) {
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    }
  });

  // TOOLTIPS
  $("img[rel=tooltip]").tooltip();
  $("span[rel=tooltip]").tooltip();
  $("i[rel=tooltip]").tooltip();
  $("input[rel=tooltip]").tooltip();

  // CHARTS PANEL CONFIGURATION
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

  // STATS PANEL CONFIGURATION
  $('a.stat-column:not(.active)').hide();
  $('a.stat-column').click(function(e) {
    $(this).toggle().removeClass('active');
    if($(this).next().length == 0) {
      $(this).parent().children('a:first').addClass('active').toggle();
    } else { 
      $(this).next().addClass('active').toggle();
    }
  }); 

  // GRID CONFIGURATION
  $('#gridnew > a').click(function(){
    $('.gridnew').show('fast');
    $('.btn-gridnew').show('fast');
    $('.gridexist').hide('fast');
    $('.btn-gridexist').hide('fast');
    $('#gridnew').addClass('active');
    $('#gridexist').removeClass('active');
  });

  $('#gridexist > a').click(function(){
    $('.gridnew').hide('fast');
    $('.btn-gridnew').hide('fast');
    $('.gridexist').show('fast');
    $('.btn-gridexist').show('fast');
    $('#gridnew').removeClass('active');
    $('#gridexist').addClass('active');
  });

  $("#form-gridnew").validate({
    rules: {
      quantity: {
        required: true,
        max: 2
      }
    },
    messages: { 
      quantity: "You must provide the number of grid nodes you wish to start. Maximum 2 nodes during beta."
    }
  });

  $("#form-gridexist").validate({
    rules: {
      slave: {
        required: true,
      }
    },
    messages: { 
      slave: "You must provide the IP of the slave grid node."
    }
  });

  $('.btn-gridnew').click(function(e) {
    e.preventDefault();
    $('#form-gridnew').submit();
  });

  $('.btn-gridexist').click(function(e) {
    e.preventDefault();
    $('#form-gridexist').submit();
  });

  // NODE CONFIGURATION
  $(".node-role").click(function(){
    $("input#host").val($(this).data('host'));
    $("input#master").val($(this).data('master'));
    $('input:radio[name=role]').filter('[value='+$(this).data('role')+']').attr('checked', true);
    $('input:radio[name=use]').filter('[value='+$(this).data('use')+']').attr('checked', true);
    $("#form-nodeconfig").attr("action", "/nodes/"+$("input#host").val());
    $('.nodeconfig').show('fast');
    $('.nodestats').children().hide();
    $('.nodestats').hide('fast');
    $('#nodeconfig').addClass('active');
    $('#nodestats').removeClass('active');

    $('.nodestats-services').html('<h4 class="alert-heading">Node Health</h4>'+$(this).attr('title')).show();
    $('.nodestats-started').html($(this).data('started'));
    $('.nodestats-stopped').html($(this).data('stopped'));
    $('.nodestats-duration').html($(this).data('duration'));
    $('.nodestats-cost').html($(this).data('cost'));

    if( $(this).data('status') == 'healthy' ) {
      $('.nodestats-services').addClass('alert-info').removeClass('alert-error');
    } else {
      $('.nodestats-services').addClass('alert-error').removeClass('alert-info');
    }


  });

  $('#nodeconfig > a').click(function(){
    $('.nodeconfig').show('fast');
    $('.nodestats').hide('fast');
    $('.nodestats').children().hide();
    $('#nodeconfig').addClass('active');
    $('#nodestats').removeClass('active');
  });

  $('#nodestats > a').click(function(){
    $('.nodeconfig').hide('fast');
    $('.nodestats').show('fast');
    $('.nodestats').children().show();
    $('#nodeconfig').removeClass('active');
    $('#nodestats').addClass('active');

  });

  $('.btn-nodeupdate').click(function(e) {
    e.preventDefault();
    $('#form-nodeconfig').submit();
  });

  $('.btn-nodedelete').click(function(e) {
    e.preventDefault();
    $("input[name=_method]").val('delete');
    $('#form-nodeconfig').submit();
  });

  // CHECK ALL GRID NODES
  $('input#checkallnodes').click(function() {
    $('input:checkbox:not(:disabled)').attr('checked', this.checked);
  });

  // RUN CONFIGURATION
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

  // FEEDBACK & SUPPORT
  $('#support > a').click(function(){
    $('.support').show('fast');
    $('.modal-footer').show('fast');
    $('.knowledge').hide('fast');
    $('#support').addClass('active');
    $('#knowledge').removeClass('active');
  });

  $('#knowledge > li > a').click(function(e){
    e.preventDefault();
    console.log($(this));
    $('.support').hide('fast');
    $('.modal-footer').hide('fast');
    $('.knowledge').show('fast').load($(this).attr('href'));
    $('#support').removeClass('active');
    $('#knowledge').addClass('active');
  });

  // EDIT RUN NOTES
  $(".notes").editable("/runs/notes", {
    name : 'notes',
    data: function(value, settings) {
      var retval = value.replace(/.*/gi, '');
      return retval;
    }
  });

  // EDIT USER ROLE
  $(".user-role").editable("/users/role", {
    name : 'role',
    data: function(value, settings) {
      var retval = value.replace(/.*/gi, '');
      return retval;
    }
  });

  // COMPARE RUNS
  $('.compare').click(function(e) {
    e.preventDefault();
    // console.log($(this));
    // console.log($('input#runs:checked'));
    alert("This feature is coming soon");
  });

  // FILTER RUNS
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

  // REMEMBER TAB
  if (location.hash !== '') $('a[href="' + location.hash + '"]').tab('show');
  return $('a[data-toggle="tab"]').on('shown', function(e) {
    return location.hash = $(e.target).attr('href').substr(1);
  });

  // TABLE SORTER
  $.tablesorter.addParser({
    id: 'fancyNumber',
    is:function(s){return false;},
    format: function(s) {return s.replace(/[\,\.]/g,'');},
    type: 'numeric'
  });
  
});