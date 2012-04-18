#
#    Copyright 2012 Northbranchlogic, Inc.
#
#    This file is part of Remove R Evaluator (rre).
#
#    rre is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    rre is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with ppe.  If not, see <http://www.gnu.org/licenses/>.
#
#    ----------------------------------------------------------------------
# 
#    RReServer.sh
#
#    Shell script for launching RReServer.
# 
#    This script is for use with ompi-ppe.  It has hardcoded references
#    to the user 'ec2-user'.
#
#    Author: Barnet Wagman
#
#    ----------------------------------------------------------------------



H=/home/ec2-user
A=/home/apps
OM=$A/openmpi

# The r executable is in /usr/local/bin.  This boot script 
# inherits the root's PATH, which by default does not contain it.
PATH=$OM/bin:$PATH:/usr/local/bin
export PATH

LD_LIBRARY_PATH=$OM/lib
export LD_LIBRARY_PATH

# KP is the keypair used to access the slaves. It is NOT the same
# as the keypair specified when the ec2 instance is launched. (The public key
# from that pair is in .ssh/authorized_keys.)
KP=$H/.ssh/ppe-keypair
OMPI_MCA_plm_rsh_agent="ssh -i $KP -l ec2-user"
export OMPI_MCA_plm_rsh_agent

OMPI_MCA_orte_default_hostfile=$H/ompi-hostfile
export OMPI_MCA_orte_default_hostfile


echo 'library(rreval); rreServer(workingDir="/home/ec2-user")' | R --no-save --no-restore --slave &




