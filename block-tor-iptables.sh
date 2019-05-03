#!/bin/bash

# block-tor-iptables blocks TOR ips using iptables.
# Copyright (C) 2019  Ramón Román Castro <ramonromancastro@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Based on https://securityonline.info/block-tor-client-iptablesiptables-tor-transparent-proxy/
# Morte info: https://github.com/godjil/block-tor-iptables

#
# CONFIGURATION
#

IPTABLES_TARGET="DROP"
IPTABLES_CHAINNAME="TOR"
IPTABLES_TOR_NODES="/tmp/tor-node-list"
IPTABLES_TOR_LOGS="/var/log/block-tor-iptables.log"

#
# MAIN CODE
#

# Comprobamos que el usuario que ejecuta el script es root

if [ "$(id -u)" != "0" ]; then
    echo "Este script debe de ejecutarse como root."
    exit 1
fi

# Creamos el agrupamiento en las tablas de iptables

if ! iptables -L $IPTABLES_CHAINNAME -n >/dev/null 2>&1 ; then 
  iptables -N $IPTABLES_CHAINNAME >/dev/null 2>&1
fi

# Descargamos la lista de nodos de TOR

rm -f $IPTABLES_TOR_NODES
wget -q -O - "https://www.dan.me.uk/torlist/" -U block-tor-iptables/1.0 > $IPTABLES_TOR_NODES

# Comprobamos la descarga
if [ $? -ne 0 ]; then
    echo "No se ha podido descargar la lista de nodos TOR. Por favor, inténtelo más tarde."
    exit 1
fi

sed -i 's|^#.*$||g' $IPTABLES_TOR_NODES

# Eliminamos los filtros actuales del agrupamiento

iptables -F $IPTABLES_CHAINNAME

# Establecemos los filtros

for IP in $(cat $IPTABLES_TOR_NODES | uniq | sort); do
	if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		echo -n '.'
		iptables -A $IPTABLES_CHAINNAME -s $IP -j $IPTABLES_TARGET
	fi
done

# Guardamos una copia en el log para tenerlo registrado

iptables-save > $IPTABLES_TOR_LOGS
