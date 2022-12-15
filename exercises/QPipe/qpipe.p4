#include <core.p4>
#define V1MODEL_VERSION 20200408
#include <v1model.p4>
#include "includes/defines.p4"
#include "includes/headers.p4"
#include "includes/parser.p4"
#include "actions.p4"

/*************************************************************************
*********************** R E G I S T E R S  *******************************
*************************************************************************/

register<bit<32>>(ARRAY_NUM) left_bound_register; // FIXME: maybe need to add <bit<32>, bit<4>>
register<bit<32>>(ARRAY_NUM) right_bound_register;
register<bit<32>>(ARRAY_NUM) length_register;
register<bit<32>>(ARRAY_NUM) head_register;
register<bit<32>>(ARRAY_NUM) tail_register;
register<bit<32>>(ARRAY_NUM) item_num_register;
register<bit<32>>(ARRAY_NUM) theta_register;
register<bit<32>>(1) beta_ing_register; // FIXME: maybe need to add <bit<32>, bit<32>>
register<bit<32>>(1) beta_exg_register;
register<bit<32>>(1) gamma_ing_register;
register<bit<32>>(1) gamma_exg_register;
register<bit<32>>(1) index_beta_ing_register;
register<bit<32>>(1) index_beta_exg_register;
register<bit<32>>(1) index_gamma_ing_register;
register<bit<32>>(1) index_gamma_exg_register;
register<bit<32>>(1) to_delete_num_register;
register<bit<32>>(ARRAY_LEN_INTOTAL) a_register; // FIXME: maybe need to add <bit<32>, bit<4>>
register<bit<32>>(ARRAY_NUM) filter_index_register; // FIXME: maybe need to add <bit<32>, bit<4>>
register<bit<32>>(ARRAY_NUM) delete_index_register;
register<bit<32>>(ARRAY_NUM) minimum_register;
register<bit<32>>(ARRAY_NUM) second_minimnum_register;
register<bit<32>>(1) array_to_operate_register; // FIXME: maybe need to add <bit<32>, bit<32>>
register<bit<32>>(1) quantile_state_register;
register<bit<32>>(1) option_type_register;

/*************************************************************************
*********************** C O N T R O L S **********************************
*************************************************************************/

control get_basic_info(inout headers hdr,
                       inout metadata meta,
                       inout standard_metadata_t standard_metadata) {

    table get_pkt_info_table {
        actions = {
            get_pkt_info_action;
        }
        default_action = get_pkt_info_action();
    }
    @pragma stage 0   // FIXME: what is pragma?
    table get_option_type_table {
        actions = {
            get_option_type_action;
        }
        default_action = get_option_type_action();
    }

    @pragma stage 0
    table get_array_to_operate_table {
        actions = {
            get_array_to_operate_action;
        }
        default_action = get_array_to_operate_action();
    }

    @pragma stage 0
    table get_quantile_state_table {
        actions = {
            get_quantile_state_action;
        }
        default_action = get_quantile_state_action();
    }

    @pragma stage 1
    table dec_to_delete_num_table {
        actions = {
            dec_to_delete_num_action;
        }
        default_action = dec_to_delete_num_action();
    }

    @pragma stage 1
    table get_beta_table {
        actions = {
            get_beta_action;
        }
        default_action = get_beta_action();
    }

    @pragma stage 1
    table get_gamma_table {
        actions = {
            get_gamma_action;
        }
        default_action = get_gamma_action();
    }

    @pragma stage 2
    table inc_meta_array_to_operate_table {
        actions = {
            inc_meta_array_to_operate_action;
        }
        default_action = inc_meta_array_to_operate_action();
    }

    @pragma stage 2
    table get_index_beta_ing_table {
        actions = {
            get_index_beta_ing_action;
        }
        default_action = get_index_beta_ing_action();
    }

    @pragma stage 2
    table get_index_gamma_ing_table {
        actions = {
            get_index_gamma_ing_action;
        }
        default_action = get_index_gamma_ing_action();
    }

    @pragma stage 3
    table get_left_bound_table {
        actions = {
            get_left_bound_action;
        }
        default_action = get_left_bound_action();
    }

    @pragma stage 3
    table get_right_bound_table {
        actions = {
            get_right_bound_action;
        }
        default_action = get_right_bound_action();
    }

    @pragma stage 3
    table get_length_table {
        actions = {
            get_length_action;
        }
        default_action = get_length_action();
    }

    @pragma stage 3
    table get_theta_table {
        actions = {
            get_theta_action;
        }
        default_action = get_theta_action();
    }

    apply {
        // ** stage 0
        // ** get the current option_type
        get_pkt_info_table.apply();
        get_option_type_table.apply();

        // ** get the target array (to operate)
        get_array_to_operate_table.apply();
        // ** get the state of the quantile (busy?)
        get_quantile_state_table.apply();

        // ** stage 1
        // dec_to_delete_num_table.apply();
        dec_to_delete_num();

        // ** get beta
        get_beta_table.apply();

        // ** get gamma
        get_gamma_table.apply();

        // ** stage 2
        // TODO: if (meta.sample != 1)
        if (meta.option_type == EXE_DELETE_OPTION) {
            if (meta.to_delete_num == 0) {
                inc_meta_array_to_operate_table.apply();
            }
        }

        // ** get_beta_index
        get_index_beta_ing_table.apply();

        // ** get_gamma_index
        get_index_gamma_ing_table.apply();

        // ** stage 3
        // ** get queue_infos
        get_left_bound_table.apply();
        get_right_bound_table.apply();

        get_length_table.apply();

        // ** get theta
        get_theta_table.apply();
    }
}

control recirculation_1 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    @pragma stage 0
    table set_option_type_table {
        actions = {
            set_option_type_action;
        }
        default_action = set_option_type_action();
    }

    @pragma stage 0
    table set_array_to_operate_table {
        actions = {
            set_array_to_operate_action;
        }
        default_action = set_array_to_operate_action();
    }

    @pragma stage 0
    table set_quantile_state_table {
        actions = {
            set_quantile_state_action;
        }
        default_action = set_quantile_state_action();
    }

    @pragma stage 1
    table set_to_delete_num_table {
        actions = {
            set_to_delete_num_action;
        }
        default_action = set_to_delete_num_action();
    }

    @pragma stage 1
    table set_beta_ing_table {
        actions = {
            set_beta_ing_action;
        }
        default_action = set_beta_ing_action();
    }

    @pragma stage 1
    table set_gamma_ing_table {
        actions = {
            set_gamma_ing_action;
        }
        default_action = set_gamma_ing_action();
    }

    @pragma stage 2
    table set_index_beta_ing_table {
        actions = {
            set_index_beta_ing_action;
        }
        default_action = set_index_beta_ing_action();
    }

    @pragma stage 2
    table set_index_gamma_ing_table {
        actions = {
            set_index_gamma_ing_action;
        }
        default_action = set_index_gamma_ing_action();
    }

    @pragma stage 3
    table set_theta_table {
        actions = {
            set_theta_action;
        }
        default_action = set_theta_action();
    }

    apply {
        // ** stage 0
        set_option_type_table.apply();
        set_array_to_operate_table.apply();

        set_quantile_state_table.apply();


        // ** stage 1
        set_to_delete_num_table.apply();

        // ** stage 1
        set_beta_ing_table.apply();
        set_gamma_ing_table.apply();

        // ** stage 2
        set_index_beta_ing_table.apply();
        set_index_gamma_ing_table.apply();

        // ** stage 3
        set_theta_table.apply();
    }
}

control recirculation_2 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) { //FIXME: check if relevant
    apply {
        // ** stage 0
        set_option_type_table.apply();

        set_array_to_operate_table.apply();

        set_quantile_state_table.apply();


        // ** stage 1
        set_to_delete_num_table.apply();

        // ** stage 1
        set_beta_ing_table.apply();
        set_gamma_ing_table.apply();

        // ** stage 2
        set_index_beta_ing_table.apply();
        set_index_gamma_ing_table.apply();

        // ** stage 3
        set_theta_table.apply();
    }
}

control recirculation_3 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) { //FIXME: check if relevant
    apply {
        // ** stage 0
        set_option_type_table.apply();

        set_array_to_operate_table.apply();

        set_quantile_state_table.apply();


        // ** stage 1
        set_to_delete_num_table.apply();

        // ** stage 1
        set_beta_ing_table.apply();
        set_gamma_ing_table.apply();

        // ** stage 2
        set_index_beta_ing_table.apply();
        set_index_gamma_ing_table.apply();

        // ** stage 3
        set_theta_table.apply();
    }
}

control recirculation_4 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    @pragma stage 1
    table set_to_delete_num_1_table {
        actions = {
            set_to_delete_num_action;
        }
        default_action = set_to_delete_num_action();
    }

    table put_value_to_theta_table {
        actions = {
            put_value_to_theta_action;
        }
        default_action = put_value_to_theta_action();
    }

    @pragma stage 6
    table swap_value_beta_table {
        actions = {
            swap_value_beta_action;
        }
        default_action = swap_value_beta_action();
    }

    apply {
        set_to_delete_num_1_table.apply();
        put_value_to_theta_table.apply();
        swap_value_beta_table.apply();
    }
}

control recirculation_5 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) {
    @pragma stage 1
    table set_to_delete_num_2_table {
        actions = {
            set_to_delete_num_action;
        }
        default_action = set_to_delete_num_action();
    }

    table put_value_to_theta_2_table {
        actions = {
            put_value_to_theta_action;
        }
        default_action = put_value_to_theta_action();
    }

    @pragma stage 6
    table swap_value_gamma_table {
        actions = {
            swap_value_gamma_action;
        }
        default_action = swap_value_gamma_action();
    }

    apply {
        // put_value_to_theta_table.apply();
        set_to_delete_num_2_table.apply();
        put_value_to_theta_2_table.apply();
        swap_value_gamma_table.apply();
    }
}

control recirculation_6 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) { //FIXME: check if relevant
    apply {
    // ** stage 0
        set_option_type_table.apply();

        set_array_to_operate_table.apply();

        set_quantile_state_table.apply();


        // ** stage 1
        set_to_delete_num_table.apply();

        // ** stage 1
        set_beta_ing_table.apply();
        set_gamma_ing_table.apply();

        // ** stage 2
        set_index_beta_ing_table.apply();
        set_index_gamma_ing_table.apply();

        // ** stage 3
        set_theta_table.apply();
    }
}

control recirculation_7 (inout headers hdr,
                         inout metadata meta,
                         inout standard_metadata_t standard_metadata) { //FIXME: check if relevant
    apply {
        // ** stage 0
        set_option_type_table.apply();

        set_array_to_operate_table.apply();

        set_quantile_state_table.apply();


        // ** stage 1
        set_to_delete_num_table.apply();

        // ** stage 1
        set_beta_ing_table.apply();
        set_gamma_ing_table.apply();

        // ** stage 2
        set_index_beta_ing_table.apply();
        set_index_gamma_ing_table.apply();

        // ** stage 3
        set_theta_table.apply();
    }
}

control inc_tail (inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    table inc_tail_read_table {
        actions = {
            inc_tail_read_action;
        }
        default_action = inc_tail_read_action();
    }

    table inc_tail_left_bound_table {
        actions = {
            inc_tail_left_bound_action;
        }
        default_action = inc_tail_left_bound_action();
    }

    table inc_tail_plus_table {
        actions = {
            inc_tail_plus_action;
        }
        default_action = inc_tail_plus_action();
    }

    table inc_tail_write_table {
        actions = {
            inc_tail_write_action;
        }
        default_action = inc_tail_write_action();
    }

    apply {
        inc_tail_read_table.apply();
        if (meta.tail == meta.right_bound) {
            inc_tail_left_bound_table.apply();
        }
        else {
            inc_tail_plus_table.apply();
        }
        inc_tail_write_table.apply();
    }
}

control inc_tail_2 (inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {
    table inc_tail_2_read_table {
        actions = {
            inc_tail_read_action;
        }
        default_action = inc_tail_read_action();
    }

    table inc_tail_2_left_bound_table {
        actions = {
            inc_tail_left_bound_action;
        }
        default_action = inc_tail_left_bound_action();
    }

    table inc_tail_2_plus_table {
        actions = {
            inc_tail_plus_action;
        }
        default_action = inc_tail_plus_action();
    }

    table inc_tail_2_write_table {
        actions = {
            inc_tail_write_action;
        }
        default_action = inc_tail_write_action();
    }

    apply {
        inc_tail_2_read_table.apply();
        if (meta.tail == meta.right_bound) {
            inc_tail_2_left_bound_table.apply();
        }
        else {
            inc_tail_2_plus_table.apply();
        }
        inc_tail_2_write_table.apply();
    }
}

control inc_item_num (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {
    table inc_item_num_read_table {
        actions = {
            inc_item_num_read_action;
        }
        default_action = inc_item_num_read_action();
    }

    table inc_item_num_plus_table {
        actions = {
            inc_item_num_plus_action;
        }
        default_action = inc_item_num_plus_action();
    }

    table inc_item_num_write_table {
        actions = {
            inc_item_num_write_action;
        }
        default_action = inc_item_num_write_action();
    }

    apply {
        inc_item_num_read_table.apply();
        if (meta.item_num != meta.len) {
            inc_item_num_plus_table.apply();
        }
        inc_item_num_write_table.apply();
    }
}

control inc_filter_index (inout headers hdr,
                          inout metadata meta,
                          inout standard_metadata_t standard_metadata) {
    table inc_filter_index_read_table {
        actions = {
            inc_filter_index_read_action;
        }
        default_action = inc_filter_index_read_action();
    }

    table inc_filter_index_left_bound_table {
        actions = {
            inc_filter_index_left_bound_action;
        }
        default_action = inc_filter_index_left_bound_action();
    }

    table inc_filter_index_plus_table {
        actions = {
            inc_filter_index_plus_action;
        }
        default_action = inc_filter_index_plus_action();
    }

    table inc_filter_index_write_table {
        actions = {
            inc_filter_index_write_action;
        }
        default_action = inc_filter_index_write_action();
    }

    apply {
        inc_filter_index_read_table.apply();
        if (meta.filter_index == meta.right_bound) {
            inc_filter_index_left_bound_table.apply();
        }
        else {
            inc_filter_index_plus_table.apply();
        }
        inc_filter_index_write_table.apply();
    }
}

control fetch_item (inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {
    table fetch_item_read_table {
        actions = {
            fetch_item_read_action;
        }
        default_action = fetch_item_read_action();
    }

    table fetch_item_assign_value_table {
        actions = {
            fetch_item_assign_value_action;
        }
        default_action = fetch_item_assign_value_action();
    }

    apply {
        fetch_item_read_table.apply();
        if (meta.a_value > meta.theta) {
            fetch_item_assign_value_table.apply();
        }
    }
}

control fetch_item_2 (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {
    table fetch_item_2_assign_value_table {
        actions = {
            fetch_item_assign_value_action;
        }
        default_action = fetch_item_assign_value_action();
    }

    table fetch_item_2_read_table {
        actions = {
            fetch_item_2_read_action;
        }
        default_action = fetch_item_2_read_action();
    }

    apply {
        fetch_item_2_read_table.apply();
        if (meta.a_value > meta.theta) {
            fetch_item_2_assign_value_table.apply();
        }
    }
}

control filter_beta (inout headers hdr,
                     inout metadata meta,
                     inout standard_metadata_t standard_metadata) {
    table filter_beta_read_table {
        actions = {
            filter_beta_read_action;
        }
        default_action = filter_beta_read_action();
    }

    table filter_beta_write_table {
        actions = {
            filter_beta_write_action;
        }
        default_action = filter_beta_write_action();
    }

    apply {
        filter_beta_read_table.apply();
        if ((meta.old_beta > meta.filter_item) && (meta.filter_item != 0)) {
            filter_beta_write_table.apply();
        }
    }
}

control filter_gamma (inout headers hdr,
                      inout metadata meta,
                      inout standard_metadata_t standard_metadata) {
    table filter_gamma_read_table {
        actions = {
            filter_gamma_read_action;
        }
        default_action = filter_gamma_read_action();
    }

    table filter_gamma_assign_value_table {
        actions = {
            filter_gamma_assign_value_action;
        }
        default_action = filter_gamma_assign_value_action();
    }

    table filter_gamma_write_table {
        actions = {
            filter_gamma_write_action;
        }
        default_action = filter_gamma_write_action();
    }

    apply {
        filter_gamma_read_table.apply();
        if ((meta.gamma > meta.max_v) && (meta.filter_item != 0)) {
            filter_gamma_assign_value_table.apply();
        }
        filter_gamma_write_table.apply();
    }
}

control inc_delete_index (inout headers hdr,
                          inout metadata meta,
                          inout standard_metadata_t standard_metadata) {
    table inc_delete_index_read_table {
        actions = {
            inc_delete_index_read_action;
        }
        default_action = inc_delete_index_read_action();
    }

    table inc_delete_index_left_bound_table {
        actions = {
            inc_delete_index_left_bound_action;
        }
        default_action = inc_delete_index_left_bound_action();
    }

    table inc_delete_index_plus_table {
        actions = {
            inc_delete_index_plus_action;
        }
        default_action = inc_delete_index_plus_action();
    }

    table inc_delete_index_write_table {
        actions = {
            inc_delete_index_write_action;
        }
        default_action = inc_delete_index_write_action();
    }

    apply {
        inc_delete_index_read_table.apply();
        if (meta.delete_index == meta.right_bound) {
            inc_delete_index_left_bound_table.apply();
        }
        else {
            inc_delete_index_plus_table.apply();
        }
        inc_delete_index_write_table.apply();
    }
}

control dec_to_delete_num (inout headers hdr,
                           inout metadata meta,
                           inout standard_metadata_t standard_metadata) {
    table dec_to_delete_num_read_table {
        actions = {
            dec_to_delete_num_read_action;
        }
        default_action = dec_to_delete_num_read_action();
    }

    table dec_to_delete_num_minus_table {
        actions = {
            dec_to_delete_num_minus_action;
        }
        default_action = dec_to_delete_num_minus_action();
    }

    table dec_to_delete_num_unchanged_table {
        actions = {
            dec_to_delete_num_unchanged_action;
        }
        default_action = dec_to_delete_num_unchanged_action();
    }

    table dec_to_delete_num_write_table {
        actions = {
            dec_to_delete_num_write_action;
        }
        default_action = dec_to_delete_num_write_action();
    }

    apply {
        dec_to_delete_num_read_table.apply();
        if ((meta.to_delete_num > 0) && (meta.option_type == EXE_DELETE_OPTION)) {
            dec_to_delete_num_minus_table.apply();
        }
        else {
            dec_to_delete_num_unchanged_table.apply();
        }
        dec_to_delete_num_write_table.apply();
    }
}

control inc_head (inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    table inc_head_read_table {
        actions = {
            inc_head_read_action;
        }
        default_action = inc_head_read_action();
    }

    table inc_head_left_bound_table {
        actions = {
            inc_head_left_bound_action;
        }
        default_action = inc_head_left_bound_action();
    }

    table inc_head_plus_table {
        actions = {
            inc_head_plus_action;
        }
        default_action = inc_head_plus_action();
    }

    table inc_head_write_table {
        actions = {
            inc_head_write_action;
        }
        default_action = inc_head_write_action();
    }

    apply {
        inc_head_read_table.apply();
        if (meta.head == meta.right_bound) {
            inc_head_left_bound_table.apply();
        }
        else {
            inc_head_plus_table.apply();
        }
        inc_head_write_table.apply();
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
        hdr.ethernet.srcAddr = smac;
        hdr.ethernet.dstAddr = dmac;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action _drop() {
        mark_to_drop(standard_metadata);
    }

    table ipv4_route {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            set_egress;
            _drop;
        }
        size = 8192;
    }

    table sample_table {
        actions = {
            sample_action;
        }
        default_action = sample_action();
    }

    table sample_01_table {
        actions = {
            sample_01_action;
        }
        default_action = sample_01_action();
    }

    @pragma stage 4
    table inc_tail_table {
        actions = {
            inc_tail_action;
        }
        default_action = inc_tail_action();
    }

    @pragma stage 5
    table inc_item_num_table {
        actions = {
            inc_item_num_action;
        }
        default_action = inc_item_num_action();
    }

    @pragma stage 6
    table put_into_array_table {
        actions = {
            put_into_array_action;
        }
        default_action = put_into_array_action();
    }

    @pragma stage 10
    table mark_to_resubmit_1_table {
        actions = {
            mark_to_resubmit_1_action;
        }
        default_action = mark_to_resubmit_1_action();
    }

    @pragma stage 4
    table inc_filter_index_table {
        actions = {
            inc_filter_index_action;
        }
        default_action = inc_filter_index_action();
    }

    @pragma stage 6
    table fetch_item_table {
        actions = {
            fetch_item_action;
        }
        default_action = fetch_item_action();
    }

    @pragma stage 7
    table filter_beta_table {
        actions = {
            filter_beta_action;
        }
        default_action = filter_beta_action();
    }

    @pragma stage 8
    table get_max_table {
        actions = {
            get_max_action;
        }
        default_action = get_max_action();
    }

    @pragma stage 8
    table get_min_table {
        actions = {
            get_min_action;
        }
        default_action = get_min_action();
    }

    @pragma stage 9
    table filter_gamma_table {
        actions = {
            filter_gamma_action;
        }
        default_action = filter_gamma_action();
    }

    @pragma stage 10
    table mark_to_resubmit_2_table {
        actions = {
            mark_to_resubmit_2_action;
        }
        default_action = mark_to_resubmit_2_action();
    }

    @pragma stage 4
    table inc_delete_index_table {
        actions = {
            inc_delete_index_action;
        }
        default_action = inc_delete_index_action();
    }

    @pragma stage 6
    table fetch_item_2_table {
        actions = {
            fetch_item_2_action;
        }
        default_action = fetch_item_2_action();
    }

    @pragma stage 7
    table mark_index_beta_table {
        actions = {
            mark_index_beta_action;
        }
        default_action = mark_index_beta_action();
    }

    @pragma stage 7
    table get_index_gamma_table {
        actions = {
            get_index_gamma_action;
        }
        default_action = get_index_gamma_action();
    }

    @pragma stage 7
    table get_index_beta_table {
        actions = {
            get_index_beta_action;
        }
        default_action = get_index_beta_action();
    }

    @pragma stage 7
    table mark_index_gamma_table {
        actions = {
            mark_index_gamma_action;
        }
        default_action = mark_index_gamma_action();
    }

    @pragma stage 10
    table mark_to_resubmit_3_table {
        actions = {
            mark_to_resubmit_3_action;
        }
        default_action = mark_to_resubmit_3_action();
    }

    @pragma stage 4
    table inc_tail_2_table {
        actions = {
            inc_tail_action;
        }
        default_action = inc_tail_action();
    }

    @pragma stage 5
    table pick_beta_table {
        actions = {
            pick_beta_action;
        }
        default_action = pick_beta_action();
    }

    @pragma stage 5
    table pick_gamma_table {
        actions = {
            pick_gamma_action;
        }
        default_action = pick_gamma_action();
    }

    @pragma stage 5
    table inc_item_num_2_table {
        actions = {
            inc_item_num_action;
        }
        default_action = inc_item_num_action();
    }

    @pragma stage 6
    table push_value_table {
        actions = {
            push_value_action;
        }
        default_action = push_value_action();
    }

    @pragma stage 10
    table mark_to_resubmit_6_table {
        actions = {
            mark_to_resubmit_6_action;
        }
        default_action = mark_to_resubmit_6_action();
    }

    @pragma stage 10
    table mark_to_resubmit_7_table {
        actions = {
            mark_to_resubmit_7_action;
        }
        default_action = mark_to_resubmit_7_action();
    }

    @pragma stage 5
    table inc_head_table {
        actions = {
            inc_head_action;
        }
        default_action = inc_head_action();
    }

    @pragma stage 6
    table get_head_value_table {
        actions = {
            get_head_value_action;
        }
        default_action = get_head_value_action();
    }

    @pragma stage 10
    table mark_to_resubmit_4_table {
        actions = {
            mark_to_resubmit_4_action;
        }
        default_action = mark_to_resubmit_4_action();
    }

    @pragma stage 10
    table mark_to_resubmit_5_table {
        actions = {
            mark_to_resubmit_5_action;
        }
        default_action = mark_to_resubmit_5_action();
    }

    table resubmit_1_table {
        actions = {
            resubmit_1_action;
        }
        default_action = resubmit_1_action();
    }

    apply
    {
        ipv4_route.apply();
        if (valid(pq_hdr)) {
            if (pq_hdr.recirc_flag == 0) {
                // ** sample pkt
                sample_table.apply();
                sample_01_table.apply();

                get_basic_info.apply(hdr, meta, standard_metadata);
                if (meta.sample == 1) {
                    // ** if the array is not full, then push the sampled value into array

                    if (meta.busy == 0) {
                        // ** stage 4
                        // ** put the value into the array

                        // inc_tail_table.apply();
                        inc_tail.apply(hdr, meta, standard_metadata);

                        // ** stage 5
                        inc_item_num_table.apply();
                        inc_item_num.apply(hdr, meta, standard_metadata);

                        // ** stage 6
                        put_into_array_table.apply();

                        if (meta.item_num == meta.len) {
                            // ** stage 10
                            mark_to_resubmit_1_table.apply();
                        }
                    }
                }
                else if (meta.sample != 1) {
                    if (meta.option_type == FILTER_OPTION) {
                        // ** stage 4
                        // ** filter minimum
                        // inc_filter_index_table.apply();
                        inc_filter_index.apply(hdr, meta, standard_metadata);

                        // ** stage 6
                        // fetch_item_table.apply();
                        fetch_item.apply(hdr, meta, standard_metadata);

                        // ** stage 7
                        // filter_beta_table.apply();
                        filter_beta.apply(hdr, meta, standard_metadata);

                        if (meta.filter_item != 0) {
                            // ** stage 8
                            // meta.max = max(meta.filter_item, meta.old_beta)
                            get_max_table.apply();
                            // meta.beta = min(meta.filter_item, meta.old_beta)
                            get_min_table.apply();
                        }
                        // ** stage 9
                        // filter_gamma_table.apply();
                        filter_gamma.apply(hdr, meta, standard_metadata);

                        if (meta.filter_index == meta.tail) {
                            // ** stage 10
                            mark_to_resubmit_2_table.apply();
                            // resubmit_1_table.apply();
                        }
                    }
                    else if (meta.option_type == PRE_DELETE_OPTION) {
                        // ** stage 4
                        // ** find the item to delete
                        // inc_delete_index_table.apply();
                        inc_delete_index.apply(hdr, meta, standard_metadata);

                        // ** stage 6
                        // fetch_item_2_table.apply();
                        fetch_item_2.apply(hdr, meta, standard_metadata);

                        if (meta.beta == meta.filter_item) {
                            // ** stage 7
                            mark_index_beta_table.apply();
                            // ** stage 7
                            get_index_gamma_table.apply();
                        }
                        else {
                            // ** stage 7
                            get_index_beta_table.apply();
                            // ** stage 7
                            if (meta.gamma == meta.filter_item) {
                                mark_index_gamma_table.apply();
                            }
                            else {
                                get_index_gamma_table.apply();
                            }
                        }

                        if (meta.delete_index == meta.tail) {
                            // ** stage 10
                            mark_to_resubmit_3_table.apply();
                        }
                    }
                    else if (meta.option_type == EXE_DELETE_OPTION) {

                        if (meta.to_delete_num == 0) {
                            // // inc_array_to_operate_table.apply();

                            // ** stage 4
                            // inc_tail_2_table.apply();
                            inc_tail_2.apply(hdr, meta, standard_metadata);

                            // ** stage 5
                            if (meta.sample_01 == 0) {
                                pick_beta_table.apply();
                            }
                            else {
                                pick_gamma_table.apply();
                            }
                            inc_item_num_2_table.apply();

                            // ** stage 6
                            push_value_table.apply();

                            if (meta.item_num == meta.len) {
                                mark_to_resubmit_6_table.apply();
                            }
                            else {
                                mark_to_resubmit_7_table.apply();
                            }

                        }
                        else {
                            // ** stage 5
                            // inc_head_table.apply();
                            inc_head.apply(hdr, meta, standard_metadata);

                            // ** stage 6
                            get_head_value_table.apply();
                            if (meta.to_delete_num == 2) {
                                // ** stage 10
                                mark_to_resubmit_4_table.apply();
                            }
                            else if (meta.to_delete_num == 1) {
                                // ** stage 10
                                mark_to_resubmit_5_table.apply();
                            }
                        }
                    }
                }
                resubmit_1_table.apply();
            }
            else if (pq_hdr.recirc_flag == 1) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 2) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 3) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 4) {
                recirculation_4.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 5) {
                recirculation_5.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 6) {
                recirculation_1.apply(hdr, meta, standard_metadata);
            }
            else if (pq_hdr.recirc_flag == 7) {
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
