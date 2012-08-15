// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

function addCommas(nStr) {
  nStr += '';
  var x = nStr.split('.');
  var x1 = x[0];
  var x2 = x.length > 1 ? '.' + x[1] : '';
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ',' + '$2');
  }
  return x1 + x2;
}

function capitalize(string)
{
  return string.charAt(0).toUpperCase() + string.slice(1);
}

function number_to_secs(n) {
  if (n >= 1000000000000)       { return addCommas((n / 1000 / 60 / 60).toFixed(2)) + "<sup>h</sup>" } 
  else if (n >= 1000000000)     { return addCommas((n / 1000 / 60).toFixed(1)) + "<sup>m</sup>" } 
  else if (n >= 1000000)        { return addCommas((n / 1000).toFixed(1)) + "<sup>s</sup>" } 
  else if (n >= 1000)           { return addCommas(n.toFixed(0)) + "<sup>ms</sup>" }
  else if (n < 1000 && n > 0)   { return addCommas(n.toFixed(0)) + "<sup>ms</sup>" }
  else if (n == 0)              { return '0' }
  else                          { return addCommas(n.toFixed(0)) }
}

function badge_colour(value) {
  if(value >= 90){
    value = '<span class="badge badge-success">'+value+'</span>'
  } else if(value >= 50) {
    value = '<span class="badge badge-warning">'+value+'</span>'
  } else {
    value = '<span class="badge badge-important">'+value+'</span>'
  }
  return value;
}

function number_to_bps(bytes) {
  if(bytes >= 125000000){
    bytes = addCommas((bytes/125000000).toFixed(2)) + '<sup>Gbps</sup>';
  } else if(bytes >= 125000){
    bytes = addCommas((bytes/125000).toFixed(2)) + '<sup>Mbps</sup>';
  } else {
    bytes = addCommas((bytes/125).toFixed(2)) + '<sup>kbps</sup>';
  }
  return bytes;
}

function number_to_human_size(bytes) {
  if(bytes < 1024)
    return bytes + '<sup>bytes</sup>';
  else if(bytes < 1024.0 * 1024.0)
    return (bytes / 1024.0).toFixed(2) + '<sup>KiB</sup>'
  else if(bytes < 1024.0 * 1024.0 * 1024.0)
    return (bytes / 1024.0 / 1024.0).toFixed(2) + '<sup>MiB</sup>'
  else
    return (bytes / 1024.0 / 1024.0 / 1024.0).toFixed(2) + '<sup>GiB</sup>';
}

function number_to_human(n) {
  if(n < 1000)
    return n;
  else if(n < 1000 * 1000)
    return (n / 1000).toFixed(0) + 'K'
  else if(n < 1000 * 1000 * 1000)
    return (n / 1000 / 1000).toFixed(1) + 'M'
  else
    return (n / 1000 / 1000 / 1000).toFixed(2) + 'B';
}

function getParameterByName(name) {
  var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
  return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
}

function HtmlEncode(s)
{
  var el = document.createElement("div");
  el.innerText = el.textContent = s;
  s = el.innerHTML;
  return s;
}