/*************************************************************************
*********************** R O U T I N G  ***********************************
*************************************************************************/

action set_egress(bit<9> egress_spec, bit<48> smac, bit<48> dmac) {
    standard_metadata.egress_spec = egress_spec;
    hdr.ethernet.srcAddr = smac;
    hdr.ethernet.dstAddr = dmac;
    hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
}

action _drop() {
    mark_to_drop(standard_metadata);
}
