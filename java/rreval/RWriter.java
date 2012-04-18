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

import java.io.*;

/**
 *
 * @author moi
 */
public class RWriter {
    
    private static final char ACK_YES = 'y';
    private static final char ACK_NO = 'n';
    
    ConnectionR con;
    private char[] ackBuffer;    
    
    public RWriter(ConnectionR con) {
        this.con = con;     
    }
    
    public void writeMessage(Message m) throws Exception {
       
        Verbose.show("RWriter.writeMessage writing");
        
        char[] typeA = m.type.toString().toCharArray();
        char[] objLenA = toPaddedString(m.obj.length(),32).toCharArray();
        char[] objA = m.obj.toCharArray();
        
        /* D */ Verbose.show("RWriter.writeMessage: " +
                    "obj=>" + m.obj + "< " +
                    "len=" + m.obj.length() +
                    "ch array len=" + m.obj.toCharArray().length);
                
        
        int nToWrite = typeA.length + objLenA.length + objA.length;
        int nWrit = 0;
        try {
                // Write the type
            con.write(typeA);
            nWrit += typeA.length;
            
                // Write the obj length
            con.write(objLenA);
            nWrit += objLenA.length;

                // Write the obj
            con.write(objA);
            nWrit += objA.length;
            Verbose.show("RWriter wrote message to R client: m=" + m);
        }
        catch(Exception x) {
            if ( nWrit >= nToWrite ) throw x;
            else {
                    // Write junk so that the full count of bytes was sent.
                Verbose.showStack("Writing junk after ex", x);
                con.write(new char [nToWrite - nWrit]);
            }
        }

            // Wait for ack
        Verbose.show("RWriter.writeMessage sent obj awaiting ack");
        char ack = readAck();        
        Verbose.show("RWriter.writeMessage got ack=" + ack);
    }
    
    String toPaddedString(int n,int len) {
        
        String s = Integer.toString(n);
        if ( s.length() < len ) {
            return( String.format("%1$#" + len + "s", s) );
        }
        else if ( s.length() == len ) return(s);
        else throw new RuntimeException("int too long: " + s);
    }
    
    char readAck() throws ReadException, IOException {
        
        ackBuffer = new char [2];
            // ^ The ack message is one char but R writeChar() adds a NULL
            //   terminator.
        if ( con.read(ackBuffer) == 2 ) {
           return( ackBuffer[0] );
        }
        else throw new ReadException("Wrong count reading ack: 2 expected");
    }
}
