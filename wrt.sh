#!/bin/sh

# Disable IPV6
uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set 'dhcp.lan.dhcpv6=disabled'
/etc/init.d/odhcpd disable
uci commit

# Disable RA and DHCPv6
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci commit dhcp
/etc/init.d/odhcpd restart

# Disable LAN
uci set network.lan.delegate="0"
uci commit network
/etc/init.d/network restart

# Disable odhcpd
/etc/init.d/odhcpd disable
/etc/init.d/odhcpd stop

# Delelte IPv6
uci -q delete network.globals.ula_prefix
uci commit network
/etc/init.d/network restart

# Simple Adblock
opkg update; opkg install curl;
opkg --force-overwrite install gawk grep sed coreutils-sort
opkg update; opkg install simple-adblock luci-app-simple-adblock
uci set simple-adblock.config.enabled=1; uci commit simple-adblock;

# Install Stubby
opkg update
opkg install stubby

# Enable DNS encryption
uci -q delete dhcp.@dnsmasq[0].server
uci get stubby.global.listen_address \
| sed -e "s/\s/\n/g;s/@/#/g" \
| while read -r STUBBY_SERV
do
uci add_list dhcp.@dnsmasq[0].server="${STUBBY_SERV}"
done

# Enforce DNS encryption for LAN clients
uci set dhcp.@dnsmasq[0].noresolv="1"

uci commit dhcp

/etc/init.d/dnsmasq restart

# Clear existing stubby config
while uci -q delete stubby.@resolver[0]; do :; done

# Add resolvers
uci set stubby.dnsa="resolver"
uci set stubby.dnsa.address="1.1.1.1"
uci set stubby.dnsa.tls_auth_name="one.one.one.one"
uci set stubby.dnsb="resolver"
uci set stubby.dnsb.address="1.0.0.1"
uci set stubby.dnsb.tls_auth_name="one.one.one.one"
uci set stubby.dnsc="resolver"
uci set stubby.dnsc.address="8.8.8.8"
uci set stubby.dnsc.tls_auth_name="dns.google"
uci set stubby.dnsd="resolver"
uci set stubby.dnsd.address="8.8.4.4"
uci set stubby.dnsd.tls_auth_name="dns.google"
uci commit stubby
/etc/init.d/stubby restart

# DNS leak test from command line
curl https://raw.githubusercontent.com/macvk/dnsleaktest/master/dnsleaktest.sh | bash
