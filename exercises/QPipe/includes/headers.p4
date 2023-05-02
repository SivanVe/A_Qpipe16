/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

struct meta_t {
    bit<16> recirc_flag;
    bit<32> sample;
    bit<1> sample_01;

    bit<1> recirced;

    bit<32> head;
    bit<32> head_n;
    bit<32> tail;
    bit<32> tail_n;
    bit<32> len;
    bit<32> item_num;
    bit<32> left_bound;
    bit<32> right_bound;
    bit<32> array_to_operate;
    bit<32> busy;
    bit<32> option_type;

    bit<32> theta;
    bit<32> beta;
    bit<32> gamma;
    bit<32> filter_index;
    bit<32> filter_index_n;
    bit<32> filter_item;
    bit<32> delete_index;
    bit<32> delete_index_n;
    bit<32> filter_item_2;
    bit<32> old_beta;
    bit<32> old_beta_index; // FIXME: new
    bit<32> max_v;
    bit<32> index_beta;
    bit<32> index_gamma;
    bit<32> to_delete_num;
    bit<32> to_delete_num_n;
    bit<32> head_v;
    bit<32> coin;
    bit<32> picked_value;
    bit<32> value;
    bit<32> a_value;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> pkt_length;
    bit<16> checksum;
}

header pq_hdr_t {
    bit<8>  op;
    bit<8>  priority;
    bit<32> value;
    bit<16> recirc_flag;
}

header recirculate_hdr_t {
    bit<32> busy;
    bit<32> option_type;
    bit<32> array_to_operate;
    bit<32> theta;
    bit<32> beta_ing;
    bit<32> gamma_ing;
    bit<32> index_beta_ing;
    bit<32> index_gamma_ing;
    bit<32> to_delete_num;
    bit<32> head; // FIXME: new
    bit<32> head_v;
}

struct metadata {
    meta_t meta;
}

struct headers {
    ethernet_t        ethernet;
    ipv4_t            ipv4;
    pq_hdr_t          pq_hdr;
    recirculate_hdr_t recirculate_hdr;
    tcp_t             tcp;
    udp_t             udp;
}
