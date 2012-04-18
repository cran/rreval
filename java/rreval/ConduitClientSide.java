/*
    Copyright 2012 Northbranchlogic, Inc.

    This file is part of Remove R Evaluator (rreval).

    rreval is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    rreval is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with rreval.  If not, see <http://www.gnu.org/licenses/>.
 */
package rreval;

import com.norbl.util.*;

/** Sends messages from the rreval client to an rreval server and returns
 *  the reply.  Because every message gets a reply, this class is
 *  client side specific. 
 *
 * @author moi
 */
public class ConduitClientSide extends MessageWrangler {
    
    
    ClientMessageHandler parent;
    
    public ConduitClientSide(ConnectionR conR, ClientMessageHandler parent) {
        setConR(conR);
        this.parent = parent;
    }    
    
    /**
     * 
     * @param m {@link Message} of type {@link MessageType#mr}
     */
    public void handleRMessage(Message m) {
        
        if ( !parent.isConnectedToClient() || !parent.isConnectedToConduit() ) {
            sendErrMToR("Not connected to an rreval server.");
            return;
        }
        
        try { conJ.writeMessage(m); } 
        catch(Exception x) { sendErrMToR("Error writing to conduit: ", x); }
        Verbose.show("ConduitClientSide; wrote R message to server side conduit.");
      
        Message r = null;
        try { r = (Message) conJ.readMessage(); }
        catch(Exception x) { sendErrMToR("Error reading from conduit: ", x); }
        Verbose.show("ConduitClientSide; read reply from server side conduit.");
        
        try { conR.writeMessage(r); }
        catch(Exception x) { sendErrMToR("Error writing to rre client: ", x); }
        Verbose.show("ConduitClientSide; wrote reply to R client.");
    }
    
}
