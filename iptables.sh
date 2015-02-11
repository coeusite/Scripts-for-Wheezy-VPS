#!/bin/bash

echo "Please enter your NAT ports (e.g. 23300:23320 ): "
read NATPORT
echo "You entered: $NATPORT"
echo "Please enter your SSH port:"
read SSHPORT
echo "You entered: $SSHPORT"

# Clean
iptables -F

# Output
iptables -A OUTPUT -j ACCEPT

# lo
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT

# Allowing Established Sessions
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allowing Ping
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport $SSHPORT -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW --dport $SSHPORT -j ACCEPT
# HTTP
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
# HTTPS
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# NAT PORTS
iptables -A INPUT -p tcp --dport $NATPORT -j ACCEPT
iptables -A INPUT -p udp --dport $NATPORT -j ACCEPT

# Drop Reset
iptables -I INPUT -p tcp --tcp-flags RST RST -j DROP
iptables -I FORWARD -p tcp --tcp-flags SYN,FIN,RST,URG,PSH RST -j DROP

# Rejecting All Others
iptables -A INPUT -j REJECT
iptables -A FORWARD -j REJECT

iptables-save > /etc/iptables.up.rules

# Clean
ip6tables -F

# lo
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT ! -i lo -d ::1 -j REJECT

# Allowing Established Sessions
ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allowing Ping
ip6tables -A INPUT -p ipv6-icmp -j ACCEPT

# Output
ip6tables -A OUTPUT -j ACCEPT

# SSH
ip6tables -A INPUT -p tcp --dport $SSHPORT -j ACCEPT
ip6tables -A INPUT -p tcp -m state --state NEW --dport $SSHPORT -j ACCEPT

# HTTP
ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT

# HTTPS
ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

# NAT PORTS
ip6tables -A INPUT -p tcp --dport $NATPORT -j ACCEPT
ip6tables -A INPUT -p udp --dport $NATPORT -j ACCEPT

# Drop Reset
ip6tables -I INPUT -p tcp --tcp-flags RST RST -j DROP
ip6tables -I FORWARD -p tcp --tcp-flags SYN,FIN,RST,URG,PSH RST -j DROP

# Rejecting All Others
ip6tables -A INPUT -j REJECT
ip6tables -A FORWARD -j REJECT

ip6tables-save > /etc/ip6tables.up.rules



cat << EOF > /etc/network/if-pre-up.d/iptables
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.up.rules
/sbin/ip6tables-restore < /etc/ip6tables.up.rules
EOF
chmod +x /etc/network/if-pre-up.d/iptables
