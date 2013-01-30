<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">

<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Slate</title>
    </head>
    <body>
        <table>
            <tr>
                <td>
                    <div id="canvasDiv"   style="border:4px solid #0080FF;">
                        <canvas id="mainCanvas" width="800" height="600"></canvas>
                    </div>
                </td>
                <td valign="top">                       
                    <div id="peerList" width="200" height="600"  style="border:1px solid #0080FF;"></div>
                </td>
            </tr>
            <table>
                <hr>
                <button onclick="closeSocket()">Close</button>
                <script type="text/javascript">
                    //Initiate the websocket connection 
                    var wsUri = "ws://" + document.location.host + document.location.pathname + "slate";
                    var websocket = new WebSocket(wsUri);            
                    websocket.binaryType = "arraybuffer";
                    var output = document.getElementById("output");
                    websocket.onmessage = function(evt) { onMessage(evt) };
                    websocket.onerror = function(evt) { onError(evt) };
                    window.onbeforeunload=function() {
                        websocket.onclose = function () {}; // disable onclose handler first
                        websocket.close()
                    };
                    function closeSocket(){
                        websocket.close();
                        alert ("websocket closed");
                    }
        
                    function onMessage(evt) {
                        console.log("received: " + evt.data);
                        if(evt.data == ""){
                            console.log("Its just a ping");
                        }else{
                            executeCommand(evt.data,true);
                        }
            
                    }

                    function onError(evt) {
                        console.log("error: " + evt.data);
                    }
        
                    var canvas = document.getElementById("mainCanvas");
                    var context = canvas.getContext("2d");
                    canvas.addEventListener('mousemove', ev_mousemove, false);
                    canvas.addEventListener('mousedown', ev_mousedown, false);
                    canvas.addEventListener('mouseup', ev_mouseup, false);
                    canvas.addEventListener('mouseout', ev_mouseout, false);

                    
                    //Touch support
                    /*
                    canvas.addEventListener('touchmove', ev_mousemove, false);
                    canvas.addEventListener('touchstart', ev_mousedown, false);
                    canvas.addEventListener('touchend', ev_mouseup, false);
                     */
                    // The mousemove event handler.
                    var started = false;
                    var isDrawing = false;
        
                    function ev_mousedown(ev){
                        var currPostion = getCoordinates(ev);
                        var x = currPostion.x;
                        var y = currPostion.y;
                        sendData('down',x,y);
                        //                        isDrawing= true;
                        //                        context.moveTo(x, y);
                    }
        
                    function ev_mouseup(){
                        sendData('up',0,0);
                        //isDrawing = false;
                        //started = false;
                    }
                    
                    function ev_mouseout(){
                        sendData('up',0,0);
                    }

 
        
                    function getCoordinates(evt){
                        var rect = canvas.getBoundingClientRect();
                        return {
                            x: evt.clientX - rect.left,
                            y: evt.clientY - rect.top
                        };    
            
                        //            var x, y;
                        //
                        //            // Get the mouse position relative to the canvas element.
                        //            if (ev.layerX || ev.layerX == 0) { // Firefox
                        //                x = ev.layerX;
                        //                y = ev.layerY;
                        //            } else if (ev.offsetX || ev.offsetX == 0) { // Opera
                        //                x = ev.offsetX;
                        //                y = ev.offsetY;
                        //            }
                        //               
                        //            return {
                        //                xx: x,
                        //                yy: y
                        //            };
                    }        
                    function ev_mousemove (ev) {            
                        var currPostion = getCoordinates(ev);
                        var x = currPostion.x;
                        var y = currPostion.y;
                    
                        // The event handler works like a drawing pencil which tracks the mouse 
                        // movements. We start drawing a path made up of lines.
            
                        if (!started) {
                            sendData('start',x,y);
                            //                            context.beginPath();
                            //                          context.moveTo(x, y);
                            //                        started = true;
                        } else {
                            if(isDrawing){
                                //context.lineTo(x, y);
                                //context.stroke();
                                sendData('move',x,y);
                            }
                        }
                    }
        
                    function sendData(command,x,y){
                        var json = JSON.stringify({
                            "cmd": command,
                            "coords": {
                                "x": x,
                                "y": y
                            }
                        });
                        executeCommand(json,false);
                        sendText(json);           
                    }
                    function executeCommand(json,isRemote){
                        var cmd = JSON.parse(json);
                        if(cmd.cmd == 'move'){
                            context.lineTo(cmd.coords.x, cmd.coords.y);
                            context.stroke();
                        }else if(cmd.cmd == 'list'){
                            console.log("List of peers"+cmd.list);
                            renderList(cmd.list);
                        } else if(cmd.cmd == 'start'){
                            context.beginPath();
                            context.moveTo(cmd.coords.x, cmd.coords.y);
                            started = true;
                        }else if(cmd.cmd == 'up'){
                            isDrawing = false;
                            started = false;
                        }else if(cmd.cmd == 'down'){
                            isDrawing= true;
                            context.moveTo(cmd.coords.x, cmd.coords.y);
                        }
                    }
                    function renderList(data){
                        var msg="Connected peers ...<br>";
                        for(var i=0;i<data.length-1;i++){//last one will be dummy 
                            var serialNumber = i+1;
                            msg = msg +'<br>'+serialNumber+". User "+ data[i];
                        }
                        document.getElementById("peerList").innerHTML = msg;
                    }
                    function sendText(json) {
                        console.log("sending text: " + json);
                        websocket.send(json);
                    }

                </script>
                </body>
                </html>
