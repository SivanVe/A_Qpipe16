#!/usr/bin/env python3

import argparse
import socket
import random
from time import sleep

from scapy.all import IP, TCP, UDP, Ether, get_if_hwaddr, get_if_list, sendp, Packet, ByteField, IntField, ShortField

class PQ(Packet):
    name = "PQ"
    fields_desc = [ ByteField("op", 0), ByteField("priority", 0), IntField("value", 11), ShortField("recirc_flag", 0) ]

def get_if():
    iface = None
    for i in get_if_list():
        if "eth0" in i:
            iface = i
            break
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--p", help="Protocol name To send TCP/UDP etc packets", type=str)
    parser.add_argument("--des", help="IP address of the destination", type=str)
    parser.add_argument("--m", help="Raw Message", type=str)
    parser.add_argument("--dur", help="in seconds", type=str)
    args = parser.parse_args()

    if args.p and args.des and args.m and args.dur:
        addr = socket.gethostbyname(args.des)
        iface = get_if()
        if args.p == 'UDP':
        #    pkt = Ether(src=get_if_hwaddr(iface), dst="ff:ff:ff:ff:ff:ff") / IP(dst=addr, tos=1) / UDP(dport=8888, sport=1234)/ PQ(op=0, priority=0, value=random.randint(0,1000), recirc_flag=0) / args.m
        #    pkt.show()
            try:
                for i in range(int(args.dur)):
                    pkt = Ether(src=get_if_hwaddr(iface), dst="ff:ff:ff:ff:ff:ff") / IP(dst=addr, tos=1) / UDP(dport=8888, sport=1234)/ PQ(op=0, priority=0, value=random.randint(300,700), recirc_flag=0) / args.m
                    sendp(pkt, iface=iface)
                    sleep(1/500000)
            except KeyboardInterrupt:
                raise
        elif args.p == 'TCP':
            pkt = Ether(src=get_if_hwaddr(iface), dst="ff:ff:ff:ff:ff:ff") / IP(dst=addr, tos=1) / TCP() / args.m
            pkt.show2()
            try:
                for i in range(int(args.dur)):
                    sendp(pkt, iface=iface)
                    sleep(1)
            except KeyboardInterrupt:
                raise


if __name__ == '__main__':
    main()
