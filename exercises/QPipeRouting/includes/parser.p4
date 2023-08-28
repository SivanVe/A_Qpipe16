/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            17: parse_udp;
            default: accept;
        }
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            PQ_PORT: parse_pq_hdr;
            default: accept;
        }
    }
    state parse_pq_hdr {
        packet.extract(hdr.pq_hdr);
        transition select(hdr.pq_hdr.recirc_flag) {
            NOT_RECIRC: accept;
            default: parse_recirculate_hdr;
        }
    }
    state parse_recirculate_hdr {
        packet.extract(hdr.recirculate_hdr);
        transition accept;
    }
}
