/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.jughyd.slate;

import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.websocket.EndpointFactory;
import javax.websocket.Session;
import javax.websocket.WebSocketClose;
import javax.websocket.WebSocketEndpoint;
import javax.websocket.WebSocketMessage;
import javax.websocket.WebSocketOpen;

/**
 *
 * @author sabghosh
 */
@WebSocketEndpoint(value = "/slate", factory = Slate.DummyEndpointFactory.class)
public class Slate {

    Set<Session> peers = Collections.synchronizedSet(new HashSet<Session>());
    List<String> msgs = Collections.synchronizedList(new LinkedList<String>());

    

    @WebSocketOpen
    public void onOpen(Session peer) {
        peers.add(peer);
        /*
        if(peer.isOpen()){
            System.out.println("-");
        }
        */
        System.out.println("New user got connected. " + peer.toString() + " Total :" + peers.size());
        broadcastPeerList();
        intializePeer(peer);
    }

    @WebSocketClose
    public void onClose(Session peer) {
        //System.out.print("User exited "+ peer.toString());
        if (peers.remove(peer)) {
            System.out.println("Session removed  Total " + peers.size());
        } else {
            System.out.println(" Could not remove the session " + peers.size());
        }
        removeDeadPeers();
        broadcastPeerList();

    }

    /*
     @WebSocketMessage
     public String sayHello(String name) {
     System.out.println("Message " + name);
     return "Hello " + name + "!";
     }
     */
    @WebSocketMessage
    public void boradcastFigure(String msg, Session session) throws IOException {
        System.out.println("Broadcasting the message " + msg);
        msgs.add(msg);
        //for (Session peer : peers) {
        for (Iterator<Session> i = peers.iterator(); i.hasNext();) {
            Session peer = i.next();
            if (!peer.equals(session)) {
                try {
                    peer.getRemote().sendString(msg);
                } catch (Exception e) {
                    System.out.println("error sending message" + peer.toString());
                    i.remove();
                    System.out.println("Removing peer. Total " + peers.size());
                }
            }
        }
    }

    private void removeDeadPeers() {
        for (Iterator<Session> i = peers.iterator(); i.hasNext();) {
            Session peer = i.next();
            try {
                peer.getRemote().sendString("");
            } catch (Exception e) {
                System.out.println("Peer Closed " + peer.toString());
                i.remove();
                System.out.println("Removing peer. Total " + peers.size());
            }
        }
    }

    private void broadcastPeerList() {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"cmd\":\"list\",\"list\":[");
        for (Session peer : peers) {
            sb.append("\"").append(peer.toString().substring(8,peer.toString().lastIndexOf(','))).append("\"");
            sb.append(",");
            //{"cmd":"move","coords":{"x":519,"y":280}}
        }
        sb.append("\"last\"]}");        
        System.out.println("Sending list of connected peers "+sb.toString());
        for (Session peer : peers) {
            try {
                peer.getRemote().sendString(sb.toString());
            } catch (IOException ex) {
                Logger.getLogger(Slate.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    private void intializePeer(Session peer) {
        System.out.print("seding the history to the new client");
        for(String msg : msgs){
            try {
                try {
                    Thread.sleep(30);
                } catch (InterruptedException ex) {
                    Logger.getLogger(Slate.class.getName()).log(Level.SEVERE, null, ex);
                }
                peer.getRemote().sendString(msg);
            } catch (IOException ex) {
                Logger.getLogger(Slate.class.getName()).log(Level.SEVERE, null, ex);
            }
        }
    }

    /**
     * Only a workaround until the API is updated. This class is not used in the
     * RI anyway.
     */
    class DummyEndpointFactory implements EndpointFactory {

        @Override
        public Object createEndpoint() {
            return null;
        }
    }
}
