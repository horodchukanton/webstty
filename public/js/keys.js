/**
 * Created by Anykey on 02.09.2015.
 */
var KEYCODE_ENTER = 13;

function keyDown(e) {
  Events.emit('key_pressed', e);
  //switch (e.keyCode) {
  //  case KEYCODE_ENTER:
  //    if (e.ctrlKey) {
  //      clickButton('go');
  //    }
  //    else {
  //      clickButton('save');
  //      clickButton('search'); //modal-search
  //    }
  //  default :
  //
  //}
}

function clickButton(id) {
  var btn = document.getElementById(id);
  if (typeof (btn) !== 'undefined' && btn !== null) btn.click();
}


//set keyboard listener
$(document).ready(function () {
  
  $('body').on('keydown', function (event) {
    keyDown(event);
  });
  
});