//NOTE ON CURRENT DESIGN : ASSUMPTION  CLK SPEED == INCOMING BYTE SEEED (will update later for more realistic results/methodologies)
//Syntax note: variables ending with _e are enums

import stock_dir_pckg::*;
module top(
  input clk,
  input reset,
  input [7:0] pcap_byte
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
  logic [31:0] payload_len;
  logic [31:0] packet_end;


  //MoldUDP64
  logic [79:0] session;
  logic [63:0] sequence_number;
  logic [15:0] message_count; //if message_count == 0xFFFF then it is a heartbeat and rest of packet can be ignored

  logic decoding_message;
  logic message_ended;
  logic [7:0] message_type;





  always_ff @(clk) begin
    if(reset) begin
      global_byte_counter <= 0;
      payload_len  <= 0;
      packet_end   <=  { 31{1'b1} };
      decoding_message <= 0;
      message_ended <= 0;
      internal_byte_counter <= 0;
      internal_message_length <= 0;
    end else begin
      if(global_byte_counter == packet_end) begin  //Reset byte counter at end of packet
        global_byte_counter <= 0;
        payload_len  <= 0;
        packet_end   <=  { 31{1'b1} };
      end else begin
        global_byte_counter <= global_byte_counter + 1;

        //Generate payload length and packet end
        case (global_byte_counter)
          42,43: payload_len                          <= {payload_len[7:0], pcap_byte}; //Get length of payload
          44: payload_len[15:8]                       <= payload_len[15:8] - 8; //Since UDP counts part of payload we minus 8
          45: packet_end                              <= global_byte_counter + packet_end;
          46,47,48,49,50,51,52,53,54,55: session      <= {session[71:0], pcap_byte};
          56,57,58,59,60,61,62,63,64: sequence_number <= {sequence_number[55:0], pcap_byte};
          65,66: message_count                        <= {message_count[7:0], pcap_byte};
        endcase

        if(message_count != 16'hffff || global_byte_counter > 66) begin //Make sure it is not a heartbeat
          //Event System Message (12 bytes)
          if(!decoding_message) begin
            internal_byte_counter <= 1;
            decoding_message <= 1;
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
            endcase
          end

          if(message_type == SYSTEM && decoding_message) begin
            internal_byte_counter <= internal_byte_counter + 1;
            case(internal_byte_counter)
              1,2:  system_event_message.sys_stock_locate        <= {system_event_message.sys_stock_locate[7:0], pcap_byte};
              3,4:  system_event_message.sys_tracking_number     <= {system_event_message.sys_tracking_number[7:0], pcap_byte};
              5,6,7,8,9:   system_event_message.sys_time_stamp   <= {system_event_message.sys_time_stamp[39:0], pcap_byte};
              10: system_event_message.sys_time_stamp[7:0]       <= pcap_byte;
              11: system_event_message.sys_event_code[7:0]       <= pcap_byte;
            endcase
            if(internal_byte_counter == 11) decoding_message <= 0;
          end
          else if(message_type == STOCK_DIR && decoding_message) begin
            case(internal_byte_counter)
              1,2: stock_directory_message.dir_stock_locate                     <= {stock_directory_message.stock_locate[7:0], pcap_byte};
              3,4: stock_directory_message.tracking_number                  <= {stock_directory_message.tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: stock_directory_message.time_stamp              <= {stock_directory_message.time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: stock_directory_message.stock_symbol <= {stock_directory_message.stock_symbol[55:0], pcap_byte};
              19: stock_directory_message.market_category                   <= pcap_byte;
              20: stock_directory_message.financial_status_indicator        <= parse_financial_status(pcap_byte);
              21,22,23,24,25,25: stock_directory_message.round_lot_size     <= {stock_directory_message.round_lot_size[23:0], pcap_byte};
              26: stock_directory_message.issue_classification              <= pcap_byte;
              27: stock_directory_message.authenticity                      <= parse_authenticity(pcap_byte);
              28: stock_directory_message.short_sale_threshold_indicator    <= parse_SST_Indicator(pcap_byte);
              29: stock_directory_message.ipo_flag                          <= parse_IPO_Flag(pcap_byte);
              30: stock_directory_message.LULUDReference_Price_Tier         <= parse_Price_Tier(pcap_byte);
              31: stock_directory_message.ETP_flag                          <= parse_ETP_Flag(pcap_byte);
              32: stock_directory_message.ETP_leverage_factor               <= pcap_byte;
              33: stock_directory_message.ETP_inverse_indicator             <= parse_ETP_inverse_indicator(pcap_byte);
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 33) decoding_message <= 0;
          end
          else if(message_type == ADD_ORDER_NO_MPID) begin
            case(internal_byte_counter)
              1,2: add_order_noMPID_message.stock_locate                               <= {add_order_noMPID_message.stock_locate[7:0], pcap_byte};
              3,4: add_order_noMPID_message.tracking_number                            <= {add_order_noMPID_message.tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: add_order_noMPID_message.time_stamp                        <= {add_order_noMPID_message.time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: add_order_noMPID_message.order_reference_number <= {add_order_noMPID_message.order_reference_number[55:0], pcap_byte};
              19: add_order_noMPID_message.buy_sell_indicator                          <= pcap_byte;
              20,21,22,23: add_order_noMPID_message.shares                             <= {add_order_noMPID_message.shares[23:0], pcap_byte};
              24,25,26,27,28,29,30,31: add_order_noMPID_message.stock                  <= {add_order_noMPID_message.stock[55:0], pcap_byte};
              32,33,34,35: add_order_noMPID_message.price                              <= {add_order_noMPID_message.price[23:0], pcap_byte};
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 35) decoding_message <= 0;
          end
          else if(message_type == ADD_ORDER_MPID) begin
            case(internal_byte_counter)
              1,2: add_order_MPID_message.stock_locate                               <= {add_order_MPID_message.stock_locate[7:0], pcap_byte};
              3,4: add_order_MPID_message.tracking_number                            <= {add_order_MPID_message.tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: add_order_MPID_message.time_stamp                        <= {add_order_MPID_message.time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: add_order_MPID_message.order_reference_number <= {add_order_MPID_message.order_reference_number[55:0], pcap_byte};
              19: add_order_MPID_message.buy_sell_indicator                          <= pcap_byte;
              20,21,22,23: add_order_MPID_message.shares                             <= {add_order_MPID_message.shares[23:0], pcap_byte};
              24,25,26,27,28,29,30,31: add_order_MPID_message.stock                  <= {add_order_MPID_message.stock[55:0], pcap_byte};
              32,33,34,35: add_order_MPID_message.price                              <= {add_order_MPID_message.price[23:0], pcap_byte};
              36,37,38,39: add_order_MPID_message.attribution                          <= {add_order_MPID_message.attribution[23:0], pcap_byte};
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 39) decoding_message <= 0;
          end
          else if (message_type == ORDER_EXEC) begin
            case(internal_byte_counter)
              1,2: order_executed_message.stock_locate                         <= {order_executed_message.stock_locate[7:0], pcap_byte};
              3,4: order_executed_message.tracking_number                      <= {order_executed_message.tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: order_executed_message.time_stamp                  <= {order_executed_message.time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: order_executed_message.reference_number <= {order_executed_message.order_reference_number[55:0], pcap_byte};
              20,21,22,23: order_executed_message.shares                       <= {order_executed_message.shares[23:0], pcap_byte};
              24,25,26,27,28,29,30,31: order_executed_message.omatch_number    <= {order_executed_message.match_number[55:0], pcap_byte};
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 39) decoding_message <= 0;
        end
      end


      end
    end
  end




endmodule