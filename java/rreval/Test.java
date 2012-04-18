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

/**
 *
 * @author moi
 */
public class Test {
    
    public static void main(String[] argv) throws Exception {
        
        ServerSocket srs = new ServerSocket(1111);
        
        Socket s = srs.accept();
        
        ConnectionR conR = new ConnectionR(s);
        RReader rr = new RReader(conR);
        RWriter rw = new RWriter(conR);
        
        for (;;) {
            Message m = rr.readMessage();
            if ( m != null ) {
                System.out.println("Message:" + m);            
                rw.writeMessage(m);
                System.out.println("Wrote message");
            }
            else System.out.println("NULL message");
        }
        
//        RWriter w = new RWriter(null, true);
//        
//        String s = w.toPaddedString(12356, 32);
//        System.out.println(">" + s + "< " + s.length());
    }
    
}
