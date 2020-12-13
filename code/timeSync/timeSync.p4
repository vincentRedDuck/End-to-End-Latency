/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "include/headers.p4"


#define MAX_PORTS 512

enum bit<16> ETHER_TYPE {IPV4 = 0x0800, timeSync = 0x9487}
enum bit<4> OPCODE_MODE {sync = 0, followUp = 1, delayReq = 2, delayResp = 3}
enum bit<2> REGISTER_TYPE {TS1 = 0, TS2 = 1, TS3 = 2, TS4 = 3}

const bit<9> PORT_TO_HOST2 = 2; //test, the port is connected to h2
const bit<16> MULTICAST_GID = 1;
const bit<9> LOOPBACK_PORT = 68;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/


struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    DPSyncTag_t  DPSyncTag;
    TS_Payload_t TS;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHER_TYPE.timeSync: parse_ipv4;
            default: reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition parse_DPSyncTag;
    }

    state parse_DPSyncTag {
        packet.extract(hdr.DPSyncTag);
        transition parse_TS;
    }

    state parse_TS {
        packet.extract(hdr.TS);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    register<bit<64>>(MAX_PORTS) TS1;
    register<bit<64>>(MAX_PORTS) TS2;
    register<bit<64>>(MAX_PORTS) TS3;
    register<bit<64>>(MAX_PORTS) TS4;

    action drop() {
        mark_to_drop(standard_metadata);
    }


    action do_updateT1(bit<9> originalPort){ 
        //parameter is (index of register array, saved value)
        TS1.write((bit<32>)originalPort, (bit<64>) hdr.TS.TS1);
    }

    action do_appendHeaderT1(bit<9> originalPort){
        bit<64> TS1Timestamp;
        //paramter is (the location which save target value temperately, index of register array)
        TS1.read(TS1Timestamp, (bit<32>)originalPort);
        hdr.TS.TS1 = TS1Timestamp;
    }

    action do_updateT2(bit<9> originalPort){ 
        TS2.write((bit<32>)originalPort, (bit<64>)standard_metadata.ingress_global_timestamp);
    }

    action do_appendHeaderT2(bit<9> originalPort){
        bit<64> TS2Timestamp;
        TS2.read(TS2Timestamp, (bit<32>)originalPort);
        hdr.TS.TS2 = TS2Timestamp;
    }

    action do_updateT3(bit<9> originalPort){ 
        TS3.write((bit<32>)originalPort, (bit<64>)standard_metadata.ingress_global_timestamp);
    }

    action do_appendHeaderT3(bit<9> originalPort){
        bit<64> TS3Timestamp;
        TS3.read(TS3Timestamp, (bit<32>)originalPort);
        hdr.TS.TS3 = TS3Timestamp;
    }

    action do_updateT4(bit<9> originalPort){ 
        TS4.write((bit<32>)originalPort, (bit<64>)standard_metadata.ingress_global_timestamp);
    }

    action do_appendHeaderT4(bit<9> originalPort){
        bit<64> TS4Timestamp;
        TS4.read(TS4Timestamp, (bit<32>)originalPort);
        hdr.TS.TS4 = TS4Timestamp;
    }

    action clearHeaderTS(){
        hdr.TS.TS1 = 0;
        hdr.TS.TS2 = 0;
        hdr.TS.TS3 = 0;
        hdr.TS.TS4 = 0;
    }

    apply
    {
        if(hdr.DPSyncTag.isValid())
        {
            if(standard_metadata.ingress_port == LOOPBACK_PORT)
            {
                //The sender is p4 switch
                if(hdr.DPSyncTag.opCode == OPCODE_MODE.delayReq)
                {
                    do_updateT3(hdr.DPSyncTag.originalPort);
                    clearHeaderTS();
                    do_appendHeaderT3(hdr.DPSyncTag.originalPort);
                    standard_metadata.egress_spec = PORT_TO_HOST2;
                }
            } 
            else
            {
                //The sender is client
                hdr.DPSyncTag.originalPort = standard_metadata.ingress_port;
                if(hdr.DPSyncTag.opCode == OPCODE_MODE.sync)
                {
                    do_updateT2(hdr.DPSyncTag.originalPort);
                    clearHeaderTS();
                    do_appendHeaderT2(hdr.DPSyncTag.originalPort);
                    hdr.DPSyncTag.opCode = OPCODE_MODE.delayReq;                    
                    standard_metadata.mcast_grp = MULTICAST_GID;
                }
                else if(hdr.DPSyncTag.opCode == OPCODE_MODE.followUp)
                {
                    do_updateT1(hdr.DPSyncTag.originalPort);
                    clearHeaderTS();
                    do_appendHeaderT1(hdr.DPSyncTag.originalPort);
                    standard_metadata.mcast_grp = MULTICAST_GID;
                }
                else if(hdr.DPSyncTag.opCode == OPCODE_MODE.delayResp)
                {
                    
                    do_updateT4(hdr.DPSyncTag.originalPort);
                    clearHeaderTS();
                    do_appendHeaderT4(hdr.DPSyncTag.originalPort);                    
                    standard_metadata.mcast_grp = MULTICAST_GID;
                }
            }

        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
   

    apply {

    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.DPSyncTag);
        packet.emit(hdr.TS);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
