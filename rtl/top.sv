module top import message_pckg::*; (
    input  clk,
    input  reset,
    input  [7:0] pcap_byte,
    input  logic valid,
    output logic msg_done,
    output logic [15:0] current_msg_num
    `ifdef DEBUG
    ,output logic [7:0]  debug_noMPID_message_type
    ,output logic [31:0] debug_noMPID_shares
    ,output logic [31:0] debug_noMPID_price
    ,output logic [63:0] debug_noMPID_stock
    ,output logic [7:0]  debug_noMPID_buy_sell
    ,output logic [7:0]  debug_MPID_message_type
    ,output logic [31:0] debug_MPID_shares
    ,output logic [31:0] debug_MPID_price
    ,output logic [63:0] debug_MPID_stock
    ,output logic [7:0]  debug_MPID_buy_sell
    ,output logic [63:0] debug_original_reference_number
    ,output logic [63:0] debug_new_order_reference_number
    ,output logic [31:0] debug_replace_shares
    ,output logic [31:0] debug_replace_price
    ,output logic [63:0] debug_executed_order_ref_num
    ,output logic [31:0] debug_executed_shares
    ,output logic [63:0] debug_executed_match_num
    ,output logic [63:0] debug_executed_with_price_order_ref_num
    ,output logic [31:0] debug_executed_with_price_shares
    ,output logic [31:0] debug_executed_with_price_price
    ,output logic [63:0] debug_executed_with_price_match_num
    ,output logic [63:0] debug_cancel_order_ref_num
    ,output logic [31:0] debug_cancel_shares
    ,output logic [63:0] debug_delete_order_ref_num
    `endif
);

    // struct instances owned by top
    Add_Order_NoMPID_Message         add_order_noMPID_message;
    Add_Order_MPID_Message           add_order_MPID_message;
    Order_Executed_Message           order_executed_message;
    Order_Executed_With_Price_Message order_executed_with_price_message;
    Order_Cancel_Message             order_cancel_message;
    Order_Delete_Message             order_delete_message;
    Order_Replace_Message            order_replace_message;
    Stock_Directory_Message          stock_directory_message;
    System_Event_Message             system_event_message;
    logic [7:0]                      message_type;

    parser u_parser (
        .clk                              (clk),
        .reset                            (reset),
        .pcap_byte                        (pcap_byte),
        .valid                            (valid),
        .msg_done                         (msg_done),
        .current_msg_num                  (current_msg_num),
        .message_type                     (message_type),
        .add_order_noMPID_message         (add_order_noMPID_message),
        .add_order_MPID_message           (add_order_MPID_message),
        .order_executed_message           (order_executed_message),
        .order_executed_with_price_message(order_executed_with_price_message),
        .order_cancel_message             (order_cancel_message),
        .order_delete_message             (order_delete_message),
        .order_replace_message            (order_replace_message),
        .stock_directory_message          (stock_directory_message),
        .system_event_message             (system_event_message)
        `ifdef DEBUG
        ,.debug_noMPID_message_type                (debug_noMPID_message_type)
        ,.debug_noMPID_shares                      (debug_noMPID_shares)
        ,.debug_noMPID_price                       (debug_noMPID_price)
        ,.debug_noMPID_stock                       (debug_noMPID_stock)
        ,.debug_noMPID_buy_sell                    (debug_noMPID_buy_sell)
        ,.debug_MPID_message_type                  (debug_MPID_message_type)
        ,.debug_MPID_shares                        (debug_MPID_shares)
        ,.debug_MPID_price                         (debug_MPID_price)
        ,.debug_MPID_stock                         (debug_MPID_stock)
        ,.debug_MPID_buy_sell                      (debug_MPID_buy_sell)
        ,.debug_original_reference_number          (debug_original_reference_number)
        ,.debug_new_order_reference_number         (debug_new_order_reference_number)
        ,.debug_replace_shares                     (debug_replace_shares)
        ,.debug_replace_price                      (debug_replace_price)
        ,.debug_executed_order_ref_num             (debug_executed_order_ref_num)
        ,.debug_executed_shares                    (debug_executed_shares)
        ,.debug_executed_match_num                 (debug_executed_match_num)
        ,.debug_executed_with_price_order_ref_num  (debug_executed_with_price_order_ref_num)
        ,.debug_executed_with_price_shares         (debug_executed_with_price_shares)
        ,.debug_executed_with_price_price          (debug_executed_with_price_price)
        ,.debug_executed_with_price_match_num      (debug_executed_with_price_match_num)
        ,.debug_cancel_order_ref_num               (debug_cancel_order_ref_num)
        ,.debug_cancel_shares                      (debug_cancel_shares)
        ,.debug_delete_order_ref_num               (debug_delete_order_ref_num)
        `endif
    );

endmodule
