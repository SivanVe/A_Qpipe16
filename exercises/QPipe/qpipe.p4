#include <core.p4>
#include <v1model.p4>
#include "includes/headers.p4"
#include "includes/defines.p4"
#include "includes/parser.p4"

/*************************************************************************
*********************** R E G I S T E R S  *******************************
*************************************************************************/

register<bit<32>>(ARRAY_NUM) left_bound_register;
register<bit<32>>(ARRAY_NUM) right_bound_register;
register<bit<32>>(ARRAY_NUM) length_register;
register<bit<32>>(ARRAY_NUM) head_register;
register<bit<32>>(ARRAY_NUM) tail_register;
register<bit<32>>(ARRAY_NUM) item_num_register;
register<bit<32>>(ARRAY_NUM) theta_register;
register<bit<32>>(1) beta_ing_register;
register<bit<32>>(1) beta_exg_register;
register<bit<32>>(1) gamma_ing_register;
register<bit<32>>(1) gamma_exg_register;
register<bit<32>>(1) index_beta_ing_register;
register<bit<32>>(1) index_beta_exg_register;
register<bit<32>>(1) index_gamma_ing_register;
register<bit<32>>(1) index_gamma_exg_register;
register<bit<32>>(1) to_delete_num_register;
register<bit<32>>(ARRAY_LEN_INTOTAL) a_register;
register<bit<32>>(ARRAY_NUM) filter_index_register;
register<bit<32>>(ARRAY_NUM) delete_index_register; // FIXME: probably unused
register<bit<32>>(1) array_to_operate_register;
register<bit<32>>(1) quantile_state_register;
register<bit<32>>(1) option_type_register;


/*************************************************************************
*********************** C O N T R O L S **********************************
*************************************************************************/
control dec_to_delete_num (inout headers hdr,
                           inout metadata meta,
                           inout standard_metadata_t standard_metadata) {

    // dec_to_delete_num
    apply {
        to_delete_num_register.read(meta.meta.to_delete_num, 0);
        if ((meta.meta.to_delete_num > 0) && (meta.meta.option_type == EXE_DELETE_OPTION)) {
            meta.meta.to_delete_num_n = meta.meta.to_delete_num - 1;
        }
        else {
            meta.meta.to_delete_num_n = meta.meta.to_delete_num;
        }
        to_delete_num_register.write(0, (bit<32>)meta.meta.to_delete_num_n);
    }
}

control get_basic_info(inout headers hdr,
                       inout metadata meta,
                       inout standard_metadata_t standard_metadata) {

    apply {
        // ** stage 0
        // ** get the current option_type
        meta.meta.value = hdr.pq_hdr.value;
        option_type_register.read(meta.meta.option_type, 0);

        // ** get the target array (to operate)
        array_to_operate_register.read(meta.meta.array_to_operate, 0);
        // ** get the state of the quantile (busy?)
        quantile_state_register.read(meta.meta.busy, 0);

        // ** stage 1
      //  dec_to_delete_num.apply(hdr, meta, standard_metadata); // FIXME: delete
        to_delete_num_register.read(meta.meta.to_delete_num, 0); // FIXME: instead dec_to_delete_num

        // ** get beta
        beta_ing_register.read(meta.meta.beta, 0);

        // ** get gamma
        gamma_ing_register.read(meta.meta.gamma, 0);

        // ** stage 2
        // TODO: if (meta.meta.sample != 1)
        if (meta.meta.option_type == EXE_DELETE_OPTION && meta.meta.to_delete_num == 0) {
            meta.meta.array_to_operate = meta.meta.array_to_operate + 1;
        }

        // ** get_beta_index
        index_beta_ing_register.read(meta.meta.index_beta, 0);

        // ** get_gamma_index
        index_gamma_ing_register.read(meta.meta.index_gamma, 0);

        // ** stage 3
        // ** get queue_infos
        left_bound_register.read(meta.meta.left_bound, (bit<32>)meta.meta.array_to_operate);
        right_bound_register.read(meta.meta.right_bound, (bit<32>)meta.meta.array_to_operate);

        length_register.read(meta.meta.len, (bit<32>)meta.meta.array_to_operate);

        // ** get theta
        theta_register.read(meta.meta.theta, (bit<32>)meta.meta.array_to_operate);
    }
}

control recirculation_1 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {

    apply {
        // ** stage 0
        option_type_register.write(0, (bit<32>)hdr.recirculate_hdr.option_type);
        array_to_operate_register.write(0, (bit<32>)hdr.recirculate_hdr.array_to_operate);

        quantile_state_register.write(0, (bit<32>)hdr.recirculate_hdr.busy);

        // ** stage 1
        to_delete_num_register.write(0, (bit<32>)hdr.recirculate_hdr.to_delete_num);

        // ** stage 1
        beta_ing_register.write(0, (bit<32>)hdr.recirculate_hdr.beta_ing);
        gamma_ing_register.write(0, (bit<32>)hdr.recirculate_hdr.gamma_ing);

        // ** stage 2
        index_beta_ing_register.write(0, (bit<32>)hdr.recirculate_hdr.index_beta_ing);
        index_gamma_ing_register.write(0, (bit<32>)hdr.recirculate_hdr.index_gamma_ing);

        // ** stage 3
        theta_register.write(0, (bit<32>)hdr.recirculate_hdr.theta);
    }
}

control recirculation_4 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    // swap - write head value to beta index
    apply {
        to_delete_num_register.write(0, (bit<32>)hdr.recirculate_hdr.to_delete_num);
        meta.meta.value = hdr.recirculate_hdr.head_v;
        a_register.write((bit<32>)hdr.recirculate_hdr.index_beta_ing, (bit<32>)meta.meta.value);
    }
}

control recirculation_5 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    // swap - write head value to gamma index
    apply {
        to_delete_num_register.write(0, 0); // FIXME: (bit<32>)hdr.recirculate_hdr.to_delete_num);
        meta.meta.value = hdr.recirculate_hdr.head_v;
        a_register.write((bit<32>)hdr.recirculate_hdr.index_gamma_ing, (bit<32>)meta.meta.value);
    }
}

control inc_tail (inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    // inc_tail
    apply {
        tail_register.read(meta.meta.tail, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.tail == meta.meta.right_bound) {
            meta.meta.tail_n = meta.meta.left_bound;
        }
        else {
            meta.meta.tail_n = meta.meta.tail + 1;
        }
        tail_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.tail_n);
    }
}

control inc_tail_2 (inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    // inc_tail
    apply {
        tail_register.read(meta.meta.tail, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.tail == meta.meta.right_bound) {
            meta.meta.tail_n = meta.meta.left_bound;
        }
        else {
            meta.meta.tail_n = meta.meta.tail + 1;
        }
        tail_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.tail_n);
    }
}

control inc_item_num (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {

    // inc_item_num
    apply {
        item_num_register.read(meta.meta.item_num, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.item_num != meta.meta.len) {
            meta.meta.item_num = meta.meta.item_num + 1;
        }
        item_num_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.item_num);
    }
}

control inc_item_num_2 (inout headers hdr,
                        inout metadata meta,
                        inout standard_metadata_t standard_metadata) {

    // inc_item_num
    apply {
        item_num_register.read(meta.meta.item_num, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.item_num != meta.meta.len) {
            meta.meta.item_num = meta.meta.item_num + 1;
        }
        item_num_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.item_num);
    }
}

control inc_filter_index (inout headers hdr,
                          inout metadata meta,
                          inout standard_metadata_t standard_metadata) {

    // inc_filter_index
    apply {
        filter_index_register.read(meta.meta.filter_index, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.filter_index == meta.meta.right_bound) {
            meta.meta.filter_index_n = meta.meta.left_bound;
        }
        else {
            meta.meta.filter_index_n = meta.meta.filter_index + 1;
        }
        filter_index_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.filter_index_n);
    }
}

control fetch_item (inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    // fetch_item
    apply {
     // a_register.read(meta.meta.a_value, (bit<32>)meta.meta.array_to_operate); // FIXME: original
        a_register.read(meta.meta.a_value, (bit<32>)meta.meta.filter_index); // FIXME: new
        if (meta.meta.a_value > meta.meta.theta) {
            meta.meta.filter_item = meta.meta.a_value;
        }
    }
}

control fetch_item_2 (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {

    apply {
        a_register.read(meta.meta.a_value, (bit<32>)meta.meta.delete_index);
        if (meta.meta.a_value > meta.meta.theta) {
            meta.meta.filter_item = meta.meta.a_value;
        }
    }
}

control filter_beta (inout headers hdr,
                     inout metadata meta,
                     inout standard_metadata_t standard_metadata) {

    // filter_beta
    apply {
        beta_exg_register.read(meta.meta.old_beta, 0);
        index_beta_exg_register.read(meta.meta.old_beta_index, 0); // FIXME: new
        if ((meta.meta.old_beta >= meta.meta.filter_item) && (meta.meta.filter_item != 0)) {
          // FIXME: the equal part supposed to help the case where the 2 min values are the same
            meta.meta.beta = meta.meta.filter_item; // FIXME: new
            meta.meta.index_beta = meta.meta.filter_index; // FIXME: new
        }
        else { // FIXME: new - instead of get_min_table
            meta.meta.beta = meta.meta.old_beta;
            meta.meta.index_beta = meta.meta.old_beta_index;
        }
        beta_exg_register.write(0, (bit<32>)meta.meta.beta);
        index_beta_exg_register.write(0, (bit<32>)meta.meta.index_beta); // FIXME: new
    }
}

control filter_gamma (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {
    // filter_gamma
    apply {
        gamma_exg_register.read(meta.meta.gamma, 0);
        index_gamma_exg_register.read(meta.meta.index_gamma, 0); // FIXME: new
        if ((meta.meta.gamma > meta.meta.filter_item ) && (meta.meta.filter_item != 0) && (meta.meta.index_beta != meta.meta.filter_index)) { // FIXME: new
            meta.meta.gamma = meta.meta.filter_item;
            meta.meta.index_gamma = meta.meta.filter_index;
        }
        if ((meta.meta.gamma > meta.meta.old_beta) && (meta.meta.index_beta != meta.meta.old_beta_index)
            && (meta.meta.index_gamma != meta.meta.index_beta)) { // FIXME: new
            meta.meta.gamma = meta.meta.old_beta;
            meta.meta.index_gamma = meta.meta.old_beta_index;
        }
    /* FIXME: delete and delete max_v
        if ((meta.meta.gamma > meta.meta.max_v) && (meta.meta.filter_item != 0) && (meta.meta.index_gamma != meta.meta.index_beta)) { // FIXME: && (meta.meta.filter_index != meta.meta.index_beta_ing)
            meta.meta.gamma = meta.meta.max_v;
        }
    */
        gamma_exg_register.write(0, (bit<32>)meta.meta.gamma);
        index_gamma_exg_register.write(0, (bit<32>)meta.meta.index_gamma); // FIXME: new
    }
}

control inc_delete_index (inout headers hdr,
                          inout metadata meta,
                          inout standard_metadata_t standard_metadata) {

    // inc_delete_index
    apply {
        delete_index_register.read(meta.meta.delete_index, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.delete_index == meta.meta.right_bound) {
            meta.meta.delete_index_n = meta.meta.left_bound;
        }
        else {
            meta.meta.delete_index_n = meta.meta.delete_index + 1;
        }
        delete_index_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.delete_index_n);
    }
}

control inc_head (inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    // inc_head
    apply {
        head_register.read(meta.meta.head, (bit<32>)meta.meta.array_to_operate);
        if (meta.meta.head == meta.meta.right_bound) {
            meta.meta.head_n = meta.meta.left_bound;
        }
        else {
            meta.meta.head_n = meta.meta.head + 1;
        }
        head_register.write((bit<32>)meta.meta.array_to_operate, (bit<32>)meta.meta.head_n);
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control ingress (inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {

    action set_egress(bit<9> egress_spec, bit<48> smac, bit<48> dmac) {
        standard_metadata.egress_spec = egress_spec;
        hdr.ethernet.srcAddr = smac; // FIXME: change smac to hdr.ethernet.dstAddr and delete in json file
        hdr.ethernet.dstAddr = dmac;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    table ipv4_route {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_egress;
            drop;
        }
        size = 8192;
    }

    @pragma stage 10
    action mark_to_resubmit_1_action() {
        hdr.pq_hdr.recirc_flag = 1;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = FILTER_OPTION;

        hdr.recirculate_hdr.theta = meta.meta.theta;
        hdr.recirculate_hdr.beta_ing = meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 0;
    }
    table mark_to_resubmit_1_table {
        actions = {
            mark_to_resubmit_1_action;
        }
        default_action = mark_to_resubmit_1_action();
    }

    @pragma stage 8
    action get_max_action() {
        if (meta.meta.filter_item > meta.meta.old_beta) { // FIXME: instead of the trinary if
            meta.meta.max_v = meta.meta.filter_item;
            meta.meta.index_gamma = meta.meta.filter_index;
        }
        else {
            meta.meta.max_v = meta.meta.old_beta;
            meta.meta.index_gamma = meta.meta.old_beta_index;
        }
    //    meta.meta.max_v = ((bit<32>)meta.meta.filter_item > (bit<32>)meta.meta.old_beta ? (bit<32>)meta.meta.filter_item : (bit<32>)meta.meta.old_beta);
    }
    table get_max_table {
        actions = {
            get_max_action;
        }
        default_action = get_max_action();
    }

    @pragma stage 8
    action get_min_action() {
        meta.meta.beta = ((bit<32>)meta.meta.filter_item <= (bit<32>)meta.meta.old_beta ? (bit<32>)meta.meta.filter_item : (bit<32>)meta.meta.old_beta);
    }
    table get_min_table {
        actions = {
            get_min_action;
        }
        default_action = get_min_action();
    }

    @pragma stage 9
    action filter_gamma_action() {}
    table filter_gamma_table {
        actions = {
            filter_gamma_action;
        }
        default_action = filter_gamma_action();
    }

    @pragma stage 10
    action mark_to_resubmit_2_action() {
        hdr.pq_hdr.recirc_flag = 2;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy= 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = PRE_DELETE_OPTION;

        hdr.recirculate_hdr.theta = meta.meta.gamma;
        hdr.recirculate_hdr.beta_ing = meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 0;
    }
    table mark_to_resubmit_2_table {
        actions = {
            mark_to_resubmit_2_action;
        }
        default_action = mark_to_resubmit_2_action();
    }

    @pragma stage 7
    action mark_index_beta_action() {
          index_beta_exg_register.write(0, (bit<32>)meta.meta.delete_index);
          meta.meta.index_beta = meta.meta.delete_index;
    }
    table mark_index_beta_table {
        actions = {
            mark_index_beta_action;
        }
        default_action = mark_index_beta_action();
    }

    @pragma stage 7
    action mark_index_gamma_action() {
          index_gamma_exg_register.write(0, (bit<32>)meta.meta.delete_index);
          meta.meta.index_gamma = meta.meta.delete_index;
    }
    table mark_index_gamma_table {
        actions = {
            mark_index_gamma_action;
        }
        default_action = mark_index_gamma_action();
    }

    @pragma stage 10
    action mark_to_resubmit_3_action() {
        hdr.pq_hdr.recirc_flag = 3;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = EXE_DELETE_OPTION;

        hdr.recirculate_hdr.theta = meta.meta.gamma;
        hdr.recirculate_hdr.beta_ing = meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 2;
    }
    table mark_to_resubmit_3_table {
        actions = {
            mark_to_resubmit_3_action;
        }
        default_action = mark_to_resubmit_3_action();
    }

    @pragma stage 10
    action mark_to_resubmit_6_action() {
        hdr.pq_hdr.recirc_flag = 6;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = FILTER_OPTION;

        hdr.recirculate_hdr.theta = meta.meta.gamma;
        hdr.recirculate_hdr.beta_ing = MAX_INT; // FIXME: was meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = MAX_INT; // FIXME: was meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = 0; // FIXME: was meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = 0; // FIXME: was meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 0;

        hdr.recirculate_hdr.head_v = meta.meta.head_v;
    }
    table mark_to_resubmit_6_table {
        actions = {
            mark_to_resubmit_6_action;
        }
        default_action = mark_to_resubmit_6_action();
    }

    @pragma stage 10
    action mark_to_resubmit_7_action() {
        hdr.pq_hdr.recirc_flag = 7;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 0;
        hdr.recirculate_hdr.array_to_operate = 0;
        hdr.recirculate_hdr.option_type = SAMPLE_OPTION;

        hdr.recirculate_hdr.theta = 0;
        hdr.recirculate_hdr.beta_ing = MAX_INT; // FIXME: was 0;
        hdr.recirculate_hdr.gamma_ing = MAX_INT;

        hdr.recirculate_hdr.index_beta_ing = 0;
        hdr.recirculate_hdr.index_gamma_ing = 0;

        hdr.recirculate_hdr.to_delete_num = 0;

        hdr.recirculate_hdr.head_v = 0;
    }
    table mark_to_resubmit_7_table {
        actions = {
            mark_to_resubmit_7_action;
        }
        default_action = mark_to_resubmit_7_action();
    }

    @pragma stage 10
    action mark_to_resubmit_4_action() {
        hdr.pq_hdr.recirc_flag = 4;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = EXE_DELETE_OPTION;

        hdr.recirculate_hdr.theta= meta.meta.gamma;
        hdr.recirculate_hdr.beta_ing = meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 1;

        hdr.recirculate_hdr.head_v = meta.meta.head_v;
    }
    table mark_to_resubmit_4_table {
        actions = {
            mark_to_resubmit_4_action;
        }
        default_action = mark_to_resubmit_4_action();
    }

    @pragma stage 10
    action mark_to_resubmit_5_action() {
        hdr.pq_hdr.recirc_flag = 5;
        hdr.recirculate_hdr.setValid();
        hdr.recirculate_hdr.busy = 1;
        hdr.recirculate_hdr.array_to_operate = meta.meta.array_to_operate;
        hdr.recirculate_hdr.option_type = EXE_DELETE_OPTION;

        hdr.recirculate_hdr.theta = meta.meta.gamma;
        hdr.recirculate_hdr.beta_ing = meta.meta.beta;
        hdr.recirculate_hdr.gamma_ing = meta.meta.gamma;

        hdr.recirculate_hdr.index_beta_ing = meta.meta.index_beta;
        hdr.recirculate_hdr.index_gamma_ing = meta.meta.index_gamma;

        hdr.recirculate_hdr.to_delete_num = 0;

        hdr.recirculate_hdr.head_v = meta.meta.head_v;
    }
    table mark_to_resubmit_5_table {
        actions = {
            mark_to_resubmit_5_action;
        }
        default_action = mark_to_resubmit_5_action();
    }

    action resubmit_1_action() {
    //    recirculate(rec_fl);
        meta.meta.recirced = 1;
    }
    table resubmit_1_table {
        actions = {
            resubmit_1_action;
        }
        default_action = resubmit_1_action();
    }
    @name(".recirculation_1") recirculation_1() recirculation_1;

    action inc_array_to_operate_action() { // FIXME: delete
        meta.meta.array_to_operate = meta.meta.array_to_operate + 1;
    }
    table inc_array_to_operate_table {
        actions = {
            inc_array_to_operate_action;
        }
        default_action = inc_array_to_operate_action();
    } // FIXME: delete

    apply
    {
        ipv4_route.apply();
        if (hdr.pq_hdr.isValid()) {
            if (hdr.pq_hdr.recirc_flag == 0) {
                // ** sample pkt
                //  random(meta.meta.sample, LOWER_BOUND, UPPER_BOUND); // FIXME
                random(meta.meta.sample, LOWER_BOUND, 3); // FIXME
                random(meta.meta.sample_01, 0, 1);

                get_basic_info.apply(hdr, meta, standard_metadata);
                if (meta.meta.sample == 1) {

                    // ** if the array is not full, then push the sampled value into array
                    if (meta.meta.busy == 0) {
                        // ** stage 4
                        // ** put the value into the array
                        inc_tail.apply(hdr, meta, standard_metadata);

                        // ** stage 5
                        inc_item_num.apply(hdr, meta, standard_metadata);

                        // ** stage 6
                        // put_into_array_table.apply();
                        a_register.write((bit<32>)meta.meta.tail, (bit<32>)meta.meta.value);

                        if (meta.meta.item_num == meta.meta.len) {
                            // ** stage 10
                            mark_to_resubmit_1_table.apply();
                        }
                    }
                }
                else if (meta.meta.sample != 1) {
                    if (meta.meta.option_type == FILTER_OPTION) {
                        // ** stage 4
                        // ** filter minimum
                        inc_filter_index.apply(hdr, meta, standard_metadata);

                        // ** stage 6
                        fetch_item.apply(hdr, meta, standard_metadata);

                        // ** stage 7
                        filter_beta.apply(hdr, meta, standard_metadata);

                        // ** stage 9
                        filter_gamma.apply(hdr, meta, standard_metadata);

                        if (meta.meta.filter_index == meta.meta.right_bound) { // FIXME: was meta.meta.tail
                            // ** stage 10
                            mark_to_resubmit_3_table.apply(); // FIXME: new - skip the PRE_DELETE_OPTION
                        }
                    }
                    else if (meta.meta.option_type == EXE_DELETE_OPTION) {
                        if (meta.meta.to_delete_num != 0) {
                            // ** stage 5
                            inc_head.apply(hdr, meta, standard_metadata);

                            // ** stage 6
                            a_register.read(meta.meta.head_v, (bit<32>)meta.meta.head); // get_head_value_table

                            if (meta.meta.to_delete_num == 2) {
                                // ** stage 10
                                mark_to_resubmit_4_table.apply();
                            }
                            else if (meta.meta.to_delete_num == 1) {
                                // ** stage 10
                                mark_to_resubmit_5_table.apply();
                            }
                        }
                        else { // meta.meta.to_delete_num == 0
                               // pushing the value and move to FILTER_OPTION
                            // ** stage 4
                            inc_tail_2.apply(hdr, meta, standard_metadata);

                            // ** stage 5
                            if (meta.meta.sample_01 == 0) {
                                meta.meta.picked_value = meta.meta.beta;
                            }
                            else {
                                meta.meta.picked_value = meta.meta.gamma;
                            }
                            inc_item_num_2.apply(hdr, meta, standard_metadata);

                            // ** stage 6
                            // ** push_value_table
                            a_register.write((bit<32>)meta.meta.tail, (bit<32>)meta.meta.picked_value); // FIXME: new

                            if (meta.meta.item_num < meta.meta.len) { // FIXME: was ==
                                // ** go to filter option
                                mark_to_resubmit_6_table.apply();
                            }
                            else {
                                // ** go to sample option
                                mark_to_resubmit_7_table.apply();
                            }
                        }
                    }
              /*
              ##########################################################################################
              ##########################################################################################
                    else if (meta.meta.option_type == EXE_DELETE_OPTION) {

                        if (meta.meta.to_delete_num == 0) {
                          //  inc_array_to_operate_table.apply(); // FIXME: was in a comment

                            // ** stage 4
                            inc_tail_2.apply(hdr, meta, standard_metadata);

                            // ** stage 5
                            if (meta.meta.sample_01 == 0) {
                                meta.meta.picked_value = meta.meta.beta;
                            }
                            else {
                                meta.meta.picked_value = meta.meta.gamma;
                            }
                            inc_item_num_2.apply(hdr, meta, standard_metadata);

                            // ** stage 6
                            // ** push_value_table
                            a_register.write((bit<32>)meta.meta.tail, (bit<32>)meta.meta.picked_value); // FIXME: new


                            if (meta.meta.item_num == meta.meta.len) {
                                // ** go to filter option
                                mark_to_resubmit_6_table.apply();
                            }
                            else {
                                // ** go to sample option
                                mark_to_resubmit_7_table.apply();
                            }
                        }
                        else {
                            // ** stage 5
                            inc_head.apply(hdr, meta, standard_metadata);

                            // ** stage 6
                            a_register.read(meta.meta.head_v, (bit<32>)meta.meta.head); // get_head_value_table
                            if (meta.meta.to_delete_num == 2) {
                                // ** stage 10
                                mark_to_resubmit_4_table.apply();
                            }
                            else if (meta.meta.to_delete_num == 1) {
                                // ** stage 10
                                mark_to_resubmit_5_table.apply();
                            }
                        }
                    }
                    ##########################################################################################
                    ##########################################################################################
              */
                }
                if (hdr.recirculate_hdr.isValid()) {
                    resubmit_1_table.apply();
                }
            }
            else if (hdr.pq_hdr.recirc_flag == 1) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 2) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 3) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 4) {
                recirculation_4.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 5) {
                recirculation_5.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 6) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (hdr.pq_hdr.recirc_flag == 7) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control egress(inout headers hdr,
               inout metadata meta,
               inout standard_metadata_t standard_metadata) {
    apply {
      if (meta.meta.recirced == 1) {
          recirculate_preserving_field_list(0);
      }
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/
control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(
            true, //FIXME: maybe hdr.ipv4.isValid() like in the tutorials
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

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.pq_hdr);
        packet.emit(hdr.recirculate_hdr);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
ParserImpl(),
verifyChecksum(),
ingress(),
egress(),
computeChecksum(),
DeparserImpl()
) main;
