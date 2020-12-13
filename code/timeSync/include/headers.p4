#ifndef HEADERS_P4
#define HEADERS_P4


header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}


header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header DPSyncTag_t{
    bit<16> etherType;
    bit<4> opCode;
    bit<3> reserved;
   // bit<9> isLoopback;
    bit<9> originalPort;
}

header TS_Payload_t{
    bit<64> TS1;
    bit<64> TS2;
    bit<64> TS3;
    bit<64> TS4;
}

#endif