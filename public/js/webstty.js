Events.on('WebSocket.connected', function (ws) {
  var $console_div = $('#console');
  
  var in_console = false;
  setup_console_management(ws, function (result) {
    if (result) {
      in_console = true;
      ws.set_raw(true, function (message) {
        $console_div.append(message);
        $console_div.append("\n# ");
        //close_console_management(ws, function (result) {
        //  console.log('In raw mode : ' + result);
        //})
      });
      $console_div.append("# pwd\n");
      ws.send('pwd\n');
    }
  });
  
  var current_string = '';
  var key_str        = {
    191: '/',
  };
  Events.on('key_pressed', function (event) {
    var keyCode = event.keyCode;
    
    //ws.send('echo hello\n');
    
    //ws.send(String.fromCharCode(keyCode).toLowerCase());
    ws.send(keyCode);
    return;
    
    if (keyCode === 13) { //Enter
      if (current_string === '') {
        ws.send('pwd');
        return;
      }
      
      //ws.send(current_string);
      //current_string = '';
      //$console_div.append("\n");
      return;
    }
    
    if (keyCode === 8) { //backspace
      current_string = current_string.substr(0, current_string.length - 1);
      
      var current_text = $console_div.text();
      var rows         = current_text.split("\n");
      rows.pop();
      
      $console_div.text(rows.join("\n"));
      
      $console_div.append("\n# " + current_string);
    }
    
    var char = '';
    if (keyCode >= 32 && keyCode <= 126) {
      char = String.fromCharCode(keyCode);
      if (!event.shiftKey) {
        char = char.toLowerCase()
      }
      
    }
    else {
      char = key_str[keyCode]
    }
    
    if (char) {
      $console_div.append(char);
      current_string += char;
      return;
    }
    
    console.log('keyUnknown ', keyCode);
  });
  
});

function setup_console_management(ws, callback) {
  
  ws.set_raw(true, function (message) {
    if (message === '{"TYPE":"RESPONCE","RESULT":"OK"}') {
      console.log('granted');
      callback(true);
    }
    else {
      console.log('revoke');
      callback(false);
    }
  });
  
  ws.send('{"TYPE":"CONSOLE_REQUEST"}');
}

function close_console_management(ws, callback) {
  ws.set_raw(false, callback);
  ws.send('{"TYPE":"CONSOLE_CLOSE"}');
}

function console_management(message) {
  console.log('[S]', message);
  
}


