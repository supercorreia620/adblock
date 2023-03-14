#!/bin/sh

# Atualizar Pacotes
opkg update

# Remover IPV6
uci set 'network.lan.ipv6=0'
uci set 'network.wan.ipv6=0'
uci set 'dhcp.lan.dhcpv6=disabled'
/etc/init.d/odhcpd disable
uci commit
uci -q delete dhcp.lan.dhcpv6
uci -q delete dhcp.lan.ra
uci commit dhcp
/etc/init.d/odhcpd restart
uci set network.lan.delegate="0"
uci commit network
/etc/init.d/network restart
/etc/init.d/odhcpd disable
/etc/init.d/odhcpd stop
uci -q delete network.globals.ula_prefix
uci commit network
/etc/init.d/network restart

# Instalar Simple AdBlock
opkg install curl
opkg --force-overwrite install gawk grep sed coreutils-sort
opkg install simple-adblock luci-app-simple-adblock
uci set simple-adblock.config.download_timeout='60'
uci set simple-adblock.config.enabled=1; uci commit simple-adblock;

# Instalar Stubby
opkg install stubby
uci -q delete dhcp.@dnsmasq[0].server
uci get stubby.global.listen_address \
| sed -e "s/\s/\n/g;s/@/#/g" \
| while read -r STUBBY_SERV
do
uci add_list dhcp.@dnsmasq[0].server="${STUBBY_SERV}"
done
uci set dhcp.@dnsmasq[0].noresolv="1"
uci commit dhcp
/etc/init.d/dnsmasq restart
while uci -q delete stubby.@resolver[0]; do :; done
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

# Trocar IP Roteador
uci set network.lan.ipaddr='192.168.247.100'
uci commit network
reboot
