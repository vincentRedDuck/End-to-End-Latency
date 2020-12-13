import struct

from scapy.packet import Packet
from scapy.fields import Field, ByteField, BitField
from scapy.utils import lhex, hexdump

class X2ByteField(Field):
    def __init__(self, name, default):
            Field.__init__(self, name, default, "!H")
    def addfield(self, pkt, s, val):
        return s + struct.pack(self.fmt, self.i2m(pkt, val))
    def getfield(self, pkt, s):
        return s[2:],s[:2]

class X8ByteField(Field):
    def __init__(self, name, default):
            Field.__init__(self, name, default, "!Q")
    def addfield(self, pkt, s, val):
        return s + struct.pack(self.fmt, self.i2m(pkt, val))
    def getfield(self, pkt, s):
        return s[8:],s[:8]

class DPSyncTag(Packet):
    name = "DPSyncTagPacket"
    fields_desc = [ X2ByteField("etherType", 0),
                BitField("opCode", 0, 4),
                BitField("reserved", 0, 3),
                BitField("originalPort", 0, 9)
                ]

class TS_Payload(Packet):
    name = "TS_PayloadPacekt"
    fields_desc = [ X8ByteField("TS1", 0),
                X8ByteField("TS2", 0),
                X8ByteField("TS3", 0),
                X8ByteField("TS4", 0)
                ]

def hexify(buffer):
    return ' '.join('%02x' % ord(c) for c in buffer)
