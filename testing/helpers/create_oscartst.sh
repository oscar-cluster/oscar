#!/bin/bash
#############################################################################
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#   Copyright (c) 2013 CEA - Commissariat à l'énergie atomique et
#                            aux énergies alternatives
#                      All rights reserved.
#   Copyright (C) 2013 Olivier LAHAYE <olivier.lahaye@cea.fr>
#                      All rights reserved.
#
# $Id: $
#
#############################################################################

# Login name for the test user.
TEST_USER=oscartst

# Generate a 12 char password for the test user:
TEST_PASSWD=$(tr -dc A-Za-z0-9_< /dev/urandom |head -c 12 | xargs)

# Create the user if it does not already exists.
if ! getent passwd $TEST_USER >/dev/null 2>&1
then
    echo "Creating '$TEST_USER' test user"
    /usr/sbin/useradd -m $TEST_USER

    echo "Setting a random password for test user".
    echo "$TEST_USER:$TEST_PASSWD" | /usr/sbin/chpasswd

    echo "Creating '$TEST_USER' ssh-key"
    /bin/su -c 'ssh-keygen -t rsa -f ~'${TEST_USER}'/.ssh/id_rsa -N ""' - ${TEST_USER} </dev/null >/dev/null 2>&1
    /bin/su -c "cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys" - ${TEST_USER} </dev/null >/dev/null 2>&1
else
    echo "User '$TEST_USER' already exists: skipping test user creation."
fi
