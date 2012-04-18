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
import java.math.*;
import java.security.*;
import com.norbl.util.*;

/** Reads a message from an R session.  The message has a type specified by
 *  a {@link MessageType}.  In response, the reader always sends back an
 * 'ack' string.
 *
 * @author Barnet Wagman
 */
public class RReader {
    
    ConnectionR con;
    
    private char[] charBuffer;  
    
    private static final char[] ACK_YES = new char[] { 'y' };
    private static final char[] ACK_NO = new char[] { 'n' };
    
    
    public RReader(ConnectionR con) {            
        this.con = con;                 
    }
    
    /** Reads a message and sends ack. Errors result in a null return
     *  but no retries.
     * 
     * @return a {@link Message}
     */
    public Message readMessage() throws Exception {        
        
        int objLen = 0;
        int nRead = 0;
        try {                        
                // Read the message type
            MessageType type = MessageType.valueOf(readChars(2+1));                      
            nRead += 2 + 1;
            
                // Read the object length.  The length is a decimal 
                // number, left padded to 32 chars.
            objLen = Integer.parseInt(readChars(32 + 1).trim());
            nRead += 32 + 1;
         
                // Read the object
            String obj = readChars(objLen + 1);
            nRead += objLen + 1;
                        
                // Read the md5
            BigInteger md5r = new BigInteger(readChars(32+1),16);
            nRead += 32 + 1;
            
                // Check the md5
            BigInteger md5 = MD5Util.calcMD5(obj);
            
            if ( md5.equals(md5r) ) {
                sendSucceededAck();
                return(new Message(type,obj,md5));
            }
            else throw new MD5MismatchException("MD5 mismatch");
        }       
        catch(Exception xx) {
            Verbose.showStack("RReader.readMessage(): ",xx);  
                // Clear the buffer of unread chars          
            Verbose.show("Clearing BufferedInputStream n=");
            if ( (xx instanceof RReaderEOFException) )
                clearBufferedInput((2+1) + (32+1) + 1 + (32+1),objLen, nRead);
                                   
            if ( (xx instanceof IllegalArgumentException) ||
                 !(xx instanceof RuntimeException) ) {
                    sendFailedAck();                                    
            }   
            throw xx;            
        }       
    }
    
    private void clearBufferedInput(int base, int objLen, int nRead) {
        int n;
        if ( objLen > 0 ) {
            n = base + objLen;
            if ( nRead >= n ) return;
        }
        else n = base + 1024;
        try {
            con.read(new char[n]);            
        } 
        catch(Exception xx) {
            System.err.println(StringUtil.exceptionStackToString(xx) + "\n" +
                               StringUtil.getExceptionMessage(xx));
        }
    }
    
    /** 
     * 
     * @param nChar the number of chars to read INCLUDING the NULL terminator
     *        that R's writeChar() adds.
     * @return
     * @throws IOException
     * @throws ReadException 
     */
    String readChars(int nChar) 
        throws IOException, ReadException, RReaderEOFException {            
        charBuffer = new char [nChar];
        int n = con.read(charBuffer);
        if ( n == nChar ) {            
            return(bufferToString(charBuffer));
        }
        else if ( n == -1 ) {
            throw new RReaderEOFException("EOF (-1) from RReader.readChars() ");
        }
        else {
            Verbose.show("RReader.readChars(): nchar=" + nChar +
                    " BUT n=" + n);
            throw new ReadException("Bad char count, " + nChar + 
                                " expected. charBuf=" + new String(charBuffer));                       
        }
    }
    
    String bufferToString(char[] b) {
        return( (new String(b)).substring(0,b.length-1) );
        // ^ R's writeChar() terminates strings with NULL.
    }
    
    void sendSucceededAck() throws IOException {
        Verbose.show("RReader sending ack=y");
        con.write(ACK_YES);
        Verbose.show("RReader sent ack=y");
    }
    
    void sendFailedAck() throws IOException {
         Verbose.show("RReader sending ack=yn");
        con.write(ACK_NO);
        Verbose.show("RReader sent ack=n");
    }
}
