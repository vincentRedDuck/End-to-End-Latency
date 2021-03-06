import argparse
import socket
import sys
import time

from definedHeader import DPSyncTag, TS_Payload
from scapy.all import sendp, get_if_list, get_if_hwaddr, hexdump
from scapy.all import Ether, IP, TCP
from scapy.all import sniff
from scapy.packet import bind_layers 


bind_layers(Ether, IP)
bind_layers(IP, DPSyncTag)
bind_layers(DPSyncTag, TS_Payload)


def get_if():
    ifs = get_if_list()
    iface = None
    print("interface")
    for i in ifs:
        print("\t" + i)
        if "eth0" in i:
            iface = i
            break
    if not iface:
        print("Cannot find eth0")
        exit(1)
    return iface




TS = TS_Payload(
    TS1 = 0,
    TS2 = 0,
    TS3 = 0,
    TS4 = 0
)

parser = argparse.ArgumentParser()
parser.add_argument('ip_addr', type = str)
args = parser.parse_args()

addr = socket.gethostbyname(args.ip_addr)

iface = get_if()


def main():
    global iface
    sniff(iface = iface, prn = lambda x: handle_pkt(x))


def handle_pkt(pkt):
    if Ether in pkt:
        if pkt[Ether].type == 0x9487 :
            if pkt[DPSyncTag].opCode == 2 :
                delayReqPkt()

def delayReqPkt():
    global iface, addr
    DPSync = DPSyncTag(
        etherType = 0x9487,
        opCode = 0b0011,
        reserved = 0,
        originalPort = 0
    )

    pkt = Ether(src=get_if_hwaddr(iface), type=0x9487, dst='ff:ff:ff:ff:ff:ff')
    pkt =pkt / IP(dst=addr) / DPSync / TS
    pkt.show()
    hexdump(pkt)
    sendp(pkt, iface=iface, verbose=False)


    

if __name__ == '__main__':
    main()