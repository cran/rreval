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

import java.net.*;
import java.io.*;

/** A socket connection to a (usually) remote java app and the associated 
 *  object stream reader and writer. Note that a {@link JReader}, {@link RWriter} 
 *  pair share the same connection (since both actually need to read and write.<p>
 * 
 *  A <tt>ConnectionJ</tt> is not itself secure.  Security is achieved 
 *  by doing communication via ssh port forwarding.
 *
 * @author Barnet Wagman
 */
public class ConnectionJ {
    
    public enum HostType { server, client }
    
    public static int MAX_WRITE_RETRIES = 16;
    public static long RETRY_NAP = 500L;
    
    private Socket socket;
    private ObjectInputStream ois;
    private ObjectOutputStream oos;
    
    private JReader jReader;
    private JWriter jWriter;
    
    boolean keepReading;

    public ConnectionJ(Socket socket, HostType type) throws IOException {
        
        this.socket = socket;
        
        if ( HostType.server.equals(type) ) {
            ois = new ObjectInputStream(socket.getInputStream()); 
            oos = new ObjectOutputStream(socket.getOutputStream());
            oos.flush();   
        }
        else if ( HostType.client.equals(type) ) {
            oos = new ObjectOutputStream(socket.getOutputStream());                 
            ois = new ObjectInputStream(socket.getInputStream()); 
        }
        else throw new RuntimeException("Undefinded HostType=" + type);
        
//        oos = new ObjectOutputStream(socket.getOutputStream());        
//        oos.flush();        
//        InputStream ins = socket.getInputStream(); /* D */
//        ois = new ObjectInputStream(ins);
//        ois = new ObjectInputStream(socket.getInputStream());                    
        jReader = new JReader(this);         
        jWriter = new JWriter(this);        
    }

    public void write(Serializable obj) throws Exception {        
        oos.writeObject(obj);
//        oos.flush();       
    } 
        
    public Serializable read() throws Exception {
        return((Serializable) ois.readObject());
    }    
    
    public void close() {
        try {
            if ( ois != null ) ois.close();
            if ( oos != null ) oos.close();
            if ( socket != null ) socket.close();
        }
        catch(IOException iox) { throw new RuntimeException(iox); }
    }    
        
    public Serializable readMessage() {
        return( jReader.readMessage() );
    }
    
    public void writeMessage(Serializable obj) throws Exception {
        jWriter.writeMessage(obj);
    }
}
