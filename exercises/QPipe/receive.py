#!/usr/bin/env python3

import sys

from scapy.all import sniff, Packet, ByteField, IntField, ShortField

class PQ(Packet):
    name = "PQ"
    fields_desc = [ ByteField("op", 0), ByteField("priority", 0), IntField("value", 11), ShortField("recirc_flag", 0) ]

def handle_pkt(pkt):
    print("got a packet")
    pkt.show2()
    sys.stdout.flush()


def main():
    iface = 'eth0'
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface=iface, prn=lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()
