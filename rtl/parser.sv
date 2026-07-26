
module parser import message_pckg::*;(
  input clk,
  input reset,
  input [7:0] pcap_byte,
  input logic valid,
  output logic msg_done, 
  output logic [15:0] current_msg_num,
  output logic [7:0] message_type,
  output logic ref_num_finished,
  output Message_Content_Ready message_content_ready,
  output Add_Order_NoMPID_Message add_order_noMPID_message,
  output Add_Order_MPID_Message add_order_MPID_message,
  output Order_Executed_Message order_executed_message,
  output Order_Executed_With_Price_Message order_executed_with_price_message,
  output Order_Cancel_Message order_cancel_message,
  output Order_Delete_Message order_delete_message,
  output Order_Replace_Message order_replace_message,
  output Stock_Directory_Message stock_directory_message,
  output System_Event_Message system_event_message

  `ifdef DEBUG
  //NOMPID
  ,output logic [7:0]  debug_noMPID_message_type
  ,output logic [31:0] debug_noMPID_shares
  ,output logic [31:0] debug_noMPID_price
  ,output logic [63:0] debug_noMPID_stock
  ,output logic [7:0] debug_noMPID_buy_sell

  //MPID
  ,output logic [7:0]  debug_MPID_message_type
  ,output logic [31:0] debug_MPID_shares
  ,output logic [31:0] debug_MPID_price
  ,output logic [63:0] debug_MPID_stock
  ,output logic [7:0] debug_MPID_buy_sell

  //Replace
  ,output logic [63:0] debug_original_reference_number
  ,output logic [63:0] debug_new_order_reference_number
  ,output logic [31:0] debug_replace_shares
  ,output logic [31:0] debug_replace_price

  //Order executed
  ,output logic [63:0] debug_executed_order_ref_num
  ,output logic [31:0] debug_executed_shares
  ,output logic [63:0] debug_executed_match_num

  //Order executed with price
  ,output logic [63:0] debug_executed_with_price_order_ref_num
  ,output logic [31:0] debug_executed_with_price_shares
  ,output logic [31:0] debug_executed_with_price_price
  ,output logic [63:0] debug_executed_with_price_match_num

  //Order cancel
  ,output logic [63:0] debug_cancel_order_ref_num
  ,output logic [31:0] debug_cancel_shares

  //Order delete
  ,output logic [63:0] debug_delete_order_ref_num

`endif


);
  /*
  NASDAQ ITCH FORMAT
    Byte 0 - 13 : Ethernet
    Byte 14 - 15 : VLAN Tag
    Byte 16- 17 : EtherType(IPv4, 0800)
    Byte 18 - 37 : IPv4 Header
    Byte 38 - 45 : User Datagram Protocol Header
    Byte 46 - onwards : Payload (MoldUPD64 and ITCH message)
  */
  logic [31:0] global_byte_counter;
  logic [31:0] internal_byte_counter;
  logic [15:0] payload_len;
  logic [31:0] packet_end;


  //MoldUDP64
  logic [79:0] session;
  logic [63:0] sequence_number;
  logic [15:0] message_count; //if message_count == 0xFFFF then it is a heartbeat and rest of packet can be ignored
  logic [15:0] message_length;
  logic [15:0] current_message_length;
  logic decoding_message;
  logic message_ended;
 logic [31:0] message_total_count;
  //FSM
  typedef enum logic [1:0] {
    MSG_LEN_HI, MSG_LEN_LO, MSG_BODY, MSG_IDLE
    } msg_state_e;
  msg_state_e msg_state;

  always_ff @(posedge clk) begin
    if(reset) begin
      global_byte_counter <= 0;
      payload_len  <= 0;
      packet_end   <=  { 32{1'b1} };
      decoding_message <= 0;
      message_ended <= 0;
      internal_byte_counter <= 0;
      message_length <= 0;
      msg_done <= 0;
      current_msg_num <= 0;
      current_message_length <= 0;
      message_total_count <= 1;
    end else begin
      if(global_byte_counter == packet_end) begin  //Reset byte counter at end of packet
        global_byte_counter <= 1;
        payload_len  <= 0;
        message_length <= 0;
        packet_end   <=  { 32{1'b1} };
        decoding_message <= 0;
        message_count       <= 0;
        current_msg_num <= 0;
        msg_done <= 0;
        current_message_length <= 0;
        msg_state <= MSG_IDLE;
        message_total_count <= message_total_count + 1;
      end else if (valid) begin
        global_byte_counter <= global_byte_counter + 1;
        msg_done <= 0;
        //Generate payload length and packet end
        case (global_byte_counter)
          42: payload_len[15:8]  <= pcap_byte;
          43: payload_len[7:0]   <= pcap_byte;
          44: payload_len                           <= payload_len; //Since UDP counts part of payload we minus 8
          45: packet_end            <= global_byte_counter + {16'b0, payload_len} + 1 - 8;
          46,47,48,49,50,51,52,53,54,55: session      <= {session[71:0], pcap_byte};
          56,57,58,59,60,61,62,63: sequence_number    <= {sequence_number[55:0], pcap_byte};
          64: message_count[15:8] <= pcap_byte;
          65: begin
            message_count[7:0]<= pcap_byte;
            msg_state <= MSG_LEN_HI;
          end
        endcase


        if(message_count != 16'hffff && global_byte_counter > 65) begin //Make sure it is not a heartbeat
           //Event System Message (12 bytes)
          case (msg_state)
            MSG_LEN_HI: begin
              //$display("MSG_LEN_HI: global_byte_counter=%0d, pcapbyte=%0h", global_byte_counter, pcap_byte);
              current_message_length[15:8] <= pcap_byte;
              msg_state <= MSG_LEN_LO;
              current_msg_num <= current_msg_num + 1;
            end
            MSG_LEN_LO: begin
             // $display("MSG_LEN_LO: global_byte_counter=%0d, pcapbyte=%0h", global_byte_counter, pcap_byte);
              current_message_length[7:0] <= pcap_byte;
              msg_state <= MSG_BODY;
            end

            MSG_BODY: begin
              if (internal_byte_counter == 0) begin
                case(pcap_byte)
                  SYSTEM                : message_type <= SYSTEM;
                  STOCK_DIR             : message_type <= STOCK_DIR;
                  ADD_ORDER_NO_MPID     : message_type <= ADD_ORDER_NO_MPID;
                  ADD_ORDER_MPID        : message_type <= ADD_ORDER_MPID;
                  ORDER_EXEC            : message_type <= ORDER_EXEC;
                  ORDER_EXEC_WITH_PRICE : message_type <= ORDER_EXEC_WITH_PRICE;
                  ORDER_CANCEL          : message_type <= ORDER_CANCEL;
                  ORDER_DELETE          : message_type <= ORDER_DELETE;
                  ORDER_REPLACE         : message_type <= ORDER_REPLACE;
                  default : message_type <= 8'hFF;
                endcase
              end
              else begin
                if(message_type == SYSTEM) begin
                  case(internal_byte_counter)
                    1,2:  system_event_message.sys_stock_locate
                      <= {system_event_message.sys_stock_locate[7:0], pcap_byte};
                    3,4:  system_event_message.sys_tracking_number
                      <= {system_event_message.sys_tracking_number[7:0], pcap_byte};
                    5,6,7,8,9:   system_event_message.sys_time_stamp
                            <= {system_event_message.sys_time_stamp[39:0], pcap_byte};
                    10: system_event_message.sys_time_stamp[7:0] <= pcap_byte;
                    11: begin system_event_message.sys_event_code[7:0] <= pcap_byte;
                    end
                  endcase
                end
                else if(message_type == ADD_ORDER_NO_MPID) begin
                  case(internal_byte_counter)
                    1,2: add_order_noMPID_message.stock_locate                               <= {add_order_noMPID_message.stock_locate[7:0], pcap_byte};
                    3,4: add_order_noMPID_message.tracking_number                            <= {add_order_noMPID_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: add_order_noMPID_message.time_stamp                        <= {add_order_noMPID_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: add_order_noMPID_message.order_reference_number <= {add_order_noMPID_message.order_reference_number[55:0], pcap_byte};
                    19: begin
                      message_content_ready.buy_sell_ready <= 1;
                      add_order_noMPID_message.buy_sell_indicator <= pcap_byte;
                    end
                    20,21,22: add_order_noMPID_message.shares <= {add_order_noMPID_message.shares[23:0], pcap_byte};
                    23: begin
                      add_order_noMPID_message.shares <= {add_order_noMPID_message.shares[23:0], pcap_byte};
                      message_content_ready.shares_ready <= 1;
                    end

                    24,25,26,27,28,29,30: add_order_noMPID_message.stock <= {add_order_noMPID_message.stock[55:0], pcap_byte};
                    32,33,34: add_order_noMPID_message.price <= {add_order_noMPID_message.price[23:0], pcap_byte};
                    35: begin
                      message_content_ready.price <= 1;
                      add_order_noMPID_message.price <= {add_order_noMPID_message.price[23:0], pcap_byte};
                    end

                  endcase
                end
                else if(message_type == ADD_ORDER_MPID) begin
                  case(internal_byte_counter)
                    1,2: add_order_MPID_message.stock_locate                               <= {add_order_MPID_message.stock_locate[7:0], pcap_byte};
                    3,4: add_order_MPID_message.tracking_number                            <= {add_order_MPID_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: add_order_MPID_message.time_stamp                        <= {add_order_MPID_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: add_order_MPID_message.order_reference_number <= {add_order_MPID_message.order_reference_number[55:0], pcap_byte};
                    19: begin
                      message_content_ready.buy_sell_ready <= 1;
                      add_order_MPID_message.buy_sell_indicator <= pcap_byte;
                    end
                    20,21,22,23: add_order_MPID_message.shares <= {add_order_MPID_message.shares[23:0], pcap_byte};
                    23: begin
                      add_order_MPID_message.shares <= {add_order_MPID_message.shares[23:0], pcap_byte};
                      message_content_ready.shares_ready <= 1;
                    end
                    24,25,26,27,28,29,30,31: add_order_MPID_message.stock  <= {add_order_MPID_message.stock[55:0], pcap_byte};
                    32,33,34: add_order_MPID_message.price <= {add_order_MPID_message.price[23:0], pcap_byte};
                    35: begin
                      message_content_ready.price <= 1;
                      add_order_MPID_message.price <= {add_order_MPID_message.price[23:0], pcap_byte};
                    end
                    36,37,38,39: add_order_MPID_message.attribution <= {add_order_MPID_message.attribution[23:0], pcap_byte};
                  endcase
                end

                else if(message_type == STOCK_DIR) begin
                  case(internal_byte_counter)
                    1,2: stock_directory_message.stock_locate                     <= {stock_directory_message.stock_locate[7:0], pcap_byte};
                    3,4: stock_directory_message.tracking_number                  <= {stock_directory_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: stock_directory_message.time_stamp              <= {stock_directory_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: stock_directory_message.stock_symbol <= {stock_directory_message.stock_symbol[55:0], pcap_byte};
                    19: stock_directory_message.market_category                   <= pcap_byte;
                    20: stock_directory_message.financial_status_indicator        <= parse_financial_status(pcap_byte);
                    21,22,23,24: stock_directory_message.round_lot_size     <= {stock_directory_message.round_lot_size[23:0], pcap_byte};
                    25: stock_directory_message.round_lots_only <= pcap_byte;
                    26: stock_directory_message.issue_classification              <= pcap_byte;
                    27: stock_directory_message.authenticity                      <= parse_authenticity(pcap_byte);
                    28: stock_directory_message.short_sale_threshold_indicator    <= parse_SST_Indicator(pcap_byte);
                    29: stock_directory_message.ipo_flag                          <= parse_IPO_Flag(pcap_byte);
                    30: stock_directory_message.LULUDReference_Price_Tier         <= parse_Price_Tier(pcap_byte);
                    31: stock_directory_message.ETP_flag                          <= parse_ETP_Flag(pcap_byte);
                    32: stock_directory_message.ETP_leverage_factor               <= pcap_byte;
                    33: begin
                      stock_directory_message.ETP_inverse_indicator             <= parse_ETP_inverse_indicator(pcap_byte);
                    end
                  endcase
                end
                else if(message_type == ORDER_REPLACE) begin
                  case(internal_byte_counter)
                    1,2: order_replace_message.stock_locate <= {order_replace_message.stock_locate[7:0], pcap_byte} ;
                    3,4: order_replace_message.tracking_number <={order_replace_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: order_replace_message.time_stamp <= {order_replace_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: order_replace_message.original_order_reference_number <= {order_replace_message.original_order_reference_number[55:0], pcap_byte}; 
                    19,20,21,22,23,24,25,26: order_replace_message.new_order_reference_number <= {order_replace_message.new_order_reference_number[55:0], pcap_byte};
                    27,28,29,30: order_replace_message.shares <= {order_replace_message.shares[23:0], pcap_byte};
                    31,32,33,34:  order_replace_message.price <= {order_replace_message.price[23:0], pcap_byte};
                  endcase
                end
                else if (message_type == ORDER_EXEC) begin
                  case(internal_byte_counter)
                    1,2: order_executed_message.stock_locate                         <= {order_executed_message.stock_locate[7:0], pcap_byte};
                    3,4: order_executed_message.tracking_number                      <= {order_executed_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: order_executed_message.time_stamp                  <= {order_executed_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: order_executed_message.order_reference_number <= {order_executed_message.order_reference_number[55:0], pcap_byte};
                    19,20,21,22: order_executed_message.shares                       <= {order_executed_message.shares[23:0], pcap_byte};
                    23,24,25,26,27,28,29,30: order_executed_message.match_number    <= {order_executed_message.match_number[55:0], pcap_byte};
                  endcase
                end
                else if (message_type == ORDER_EXEC_WITH_PRICE) begin
                  case(internal_byte_counter)
                    1,2: order_executed_with_price_message.stock_locate                         <= {order_executed_with_price_message.stock_locate[7:0], pcap_byte};
                    3,4: order_executed_with_price_message.tracking_number                      <= {order_executed_with_price_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: order_executed_with_price_message.time_stamp                  <= {order_executed_with_price_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: order_executed_with_price_message.order_reference_number <= {order_executed_with_price_message.order_reference_number[55:0], pcap_byte};
                    19,20,21,22: order_executed_with_price_message.shares                       <= {order_executed_with_price_message.shares[23:0], pcap_byte};
                    23,24,25,26,27,28,29,30: order_executed_with_price_message.match_number    <= {order_executed_with_price_message.match_number[55:0], pcap_byte};
                    31: order_executed_with_price_message.printable <= pcap_byte;
                    32,33,34,35: order_executed_with_price_message.price <= {order_executed_with_price_message.price[23:0], pcap_byte};
                  endcase
                end
                else if (message_type == ORDER_CANCEL) begin
                  case(internal_byte_counter)
                    1,2: order_cancel_message.stock_locate                         <= {order_cancel_message.stock_locate[7:0], pcap_byte};
                    3,4: order_cancel_message.tracking_number                      <= {order_cancel_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: order_cancel_message.time_stamp                  <= {order_cancel_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: order_cancel_message.order_reference_number <= {order_cancel_message.order_reference_number[55:0], pcap_byte};
                    19,20,21: order_cancel_message.shares              <= {order_cancel_message.shares[23:0], pcap_byte};
                    22: begin
                      order_cancel_message.shares              <= {order_cancel_message.shares[23:0], pcap_byte};
                      message_content_ready.shares<= 1;
                    end
                  endcase
                end
                else if (message_type == ORDER_DELETE) begin
                  case(internal_byte_counter)
                    1,2: order_delete_message.stock_locate                         <= {order_delete_message.stock_locate[7:0], pcap_byte};
                    3,4: order_delete_message.tracking_number                      <= {order_delete_message.tracking_number[7:0], pcap_byte};
                    5,6,7,8,9,10: order_delete_message.time_stamp                  <= {order_delete_message.time_stamp[39:0], pcap_byte};
                    11,12,13,14,15,16,17,18: order_delete_message.order_reference_number <= {order_delete_message.order_reference_number[55:0], pcap_byte};
                  endcase
                end
              end

              if( internal_byte_counter >= 18) ref_num_finished <= 1;
              else ref_num_finished <= 0;

              if(internal_byte_counter == {16'd0, current_message_length} - 32'd1) begin
                msg_state <= MSG_LEN_HI;
                msg_done <= 1;
                internal_byte_counter <= 0;
              //  $display("FALLBACK, msg_done fired, internal_byte_counter=%0d, message_length=%0d, current_msg_num=%0d, message_type=%0d", internal_byte_counter, message_length, current_msg_num, message_type);
              end
              else internal_byte_counter <= internal_byte_counter + 1;
            end
          default: msg_state <= MSG_IDLE;
          endcase
      end
      end

    end
  end


  `ifdef DEBUG
  //NoMPID
  assign debug_noMPID_message_type  = message_type;
  assign debug_noMPID_shares        = add_order_noMPID_message.shares;
  assign debug_noMPID_price         = add_order_noMPID_message.price;
  assign debug_noMPID_stock         = add_order_noMPID_message.stock;
  assign debug_noMPID_buy_sell      = add_order_noMPID_message.buy_sell_indicator;
  //MPID
  assign debug_MPID_message_type  = message_type;
  assign debug_MPID_shares        = add_order_MPID_message.shares;
  assign debug_MPID_price         = add_order_MPID_message.price;
  assign debug_MPID_stock         = add_order_MPID_message.stock;
  assign debug_MPID_buy_sell      = add_order_MPID_message.buy_sell_indicator;

  //Order replace
  assign debug_original_reference_number = order_replace_message.original_order_reference_number;
  assign debug_new_order_reference_number = order_replace_message.new_order_reference_number;
  assign debug_replace_shares = order_replace_message.shares;
  assign debug_replace_price = order_replace_message.price;

  //Order executed
  assign debug_executed_order_ref_num = order_executed_message.order_reference_number;
  assign debug_executed_shares = order_executed_message.shares;
  assign debug_executed_match_num = order_executed_message.match_number;

  //Order executed with price
  assign debug_executed_with_price_order_ref_num = order_executed_with_price_message.order_reference_number;
  assign debug_executed_with_price_shares = order_executed_with_price_message.shares;
  assign debug_executed_with_price_price = order_executed_with_price_message.price;
  assign debug_executed_with_price_match_num = order_executed_with_price_message.match_number;

  //Order cancel
  assign debug_cancel_order_ref_num = order_cancel_message.order_reference_number;
  assign debug_cancel_shares = order_cancel_message.shares;

  //Order delete
  assign debug_delete_order_ref_num = order_delete_message.order_reference_number;
`endif




endmodule
