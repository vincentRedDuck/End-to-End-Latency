import argparse
import socket
import sys
import time

from definedHeader import DPSyncTag, TS_Payload
from scapy.all import sendp, get_if_list, get_if_hwaddr, hexdump
from scapy.all import Ether, IP, TCP
from scapy.all import sniff
from scapy.packet import bind_layers 
from enum import Enum

class OPCODE_MODE(Enum):
    sync = 0x0 
    followUp = 0x1 
    delayReq = 0x2 
    delayResp = 0x3


bind_layers(Ether, IP)
bind_layers(IP, DPSyncTag)
bind_layers(DPSyncTag, TS_Payload)

TS1 = 0
TS2 = 0
TS3 = 0
TS4 = 0


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

iface = get_if()


def main():
    global iface
    print("start to sniff!!\n")
    sniff(iface = iface, prn = lambda x: handle_pkt(x))


def handle_pkt(pkt):
    global TS1,TS2,TS3,TS4
    if Ether in pkt:
        if pkt[Ether].type == 0x9487:
            if IP in pkt:
                if pkt[IP].dst != pkt[IP].src:
                    if DPSyncTag in pkt:  
                        if pkt[DPSyncTag].opCode != 2:                      
                            print("receive a packet!!!!\n")
                            pkt.show()
                
                            if pkt[DPSyncTag].opCode == 0:
                                TS2 = int(round(time.time() * 1000 * 1000 * 1000)) #naro second
                                sendDelayReqPkt(pkt)
                                TS3 = int(round(time.time() * 1000 * 1000 * 1000)) #naro second
                            elif pkt[DPSyncTag].opCode == 1:
                                TS1 = pkt[TS_Payload].TS1                
                            elif pkt[DPSyncTag].opCode == 3:
                                TS4 = pkt[TS_Payload].TS4
                                echoTS()
            

def sendDelayReqPkt(pkt):
    global iface
    DPSync = DPSyncTag(
        etherType = 0x9487,
        opCode = 0b0010,
        reserved = 0,
        originalPort = 0
    )
    pkt2 = Ether(src=get_if_hwaddr(iface), type=0x9487, dst='ff:ff:ff:ff:ff:ff')
    pkt2 =pkt2 / IP(dst=pkt[IP].src, src=pkt[IP].dst) / DPSync / TS
    print("send the delay-req packet!!\n")
    pkt2.show()
    hexdump(pkt2)
    sendp(pkt2, iface=iface, verbose=False)

def echoTS():
    global TS1,TS2,TS3,TS4
    print(int.from_bytes(TS1, byteorder='big'))
    print(TS2)    
    print(TS3)
    print(int.from_bytes(TS4, byteorder='big'))


    

if __name__ == '__main__':
    main()