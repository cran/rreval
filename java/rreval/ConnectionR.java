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

/** A socket connection to a local R session and the associated stream reader
 *  and writer. Note that an {@link RReader}, {@link RWriter} pair share the
 *  same connection (since both actually need to read and write.
 *
 * @author Barnet Wagman
 */
public class ConnectionR {
    
    private Socket socket;
    private BufferedReader reader;       
    private BufferedWriter writer;
    
    private RReader rReader;
    private RWriter rWriter;
    
    public ConnectionR(Socket socket) throws IOException {
        this.socket = socket;
        reader = new BufferedReader(
                            new InputStreamReader(socket.getInputStream()));
        writer = new BufferedWriter(
                            new OutputStreamWriter(socket.getOutputStream()));
        rReader = new RReader(this);
        rWriter = new RWriter(this);
    }
    
    public int read(char[] buffer) throws IOException {        
        return( reader.read(buffer, 0, buffer.length) );
    }
    
    public void write(char[] buffer) throws IOException {
        writer.write(buffer, 0, buffer.length);
        writer.flush();
    }
    
    public void close() {
        try {
            if ( reader != null ) reader.close();
            if ( writer != null ) writer.close();
        }
        catch(IOException iox) { throw new RuntimeException(iox); }
    }
    
    public Message readMessage() throws Exception {
        return(rReader.readMessage());
    }
    
    public void writeMessage(Message m) throws Exception {
        rWriter.writeMessage(m);
    }
}
