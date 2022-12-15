action set_egress(egress_spec, smac, dmac) {
    modify_field(standard_metadata.egress_spec, egress_spec);
    modify_field (ethernet.srcAddr, smac);
    modify_field (ethernet.dstAddr, dmac);
    add_to_field(ipv4.ttl, -1);
}

table ipv4_route {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_egress;
        _drop;
    }
    size : 8192;
}

action ethernet_set_mac_act (smac, dmac) {
    modify_field (ethernet.srcAddr, smac);
    modify_field (ethernet.dstAddr, dmac);
}

table ethernet_set_mac {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        ethernet_set_mac_act;
        _no_op;
    }
}

action _no_op() {
    no_op();
}

action _drop() {
    drop();
}
