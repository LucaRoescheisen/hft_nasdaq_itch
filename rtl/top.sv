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


   typedef enum logic [3:0] {
    SYSTEM                = "S",
    STOCK_DIR             = "R",
    ADD_ORDER_NO_MPID     = "A",
    ADD_ORDER_MPID        = "F",
    ORDER_EXEC            = "E",
    ORDER_EXEC_WITH_PRICE = "C",
    ORDER_CANCEL          = "X",
    ORDER_DELETE          = "D",
    ORDER_REPLACE         = "U"
  } message_states_e;


  typedef enum logic [2:0] {
    SYSTEM_EVENT_MESSAGE_LENGTH  = 12,
    ...

  } message_lengths;

  //SYSTEM MESSAGE

  typedef struct packed {
    logic [7:0]  sys_message_type;
    logic [15:0] sys_stock_locate;
    logic [15:0] sys_tracking_number;
    logic [47:0] sys_time_stamp;
    logic [7:0]  sys_event_code;
  } System_Event_Message;
  System_Event_Message system_event_message;

  typedef enum logic [7:0] {
    EVENT_START_MESSAGES = "O" ,
    EVENT_START_SYSTEM   = "S" ,
    EVENT_START_MARKET   = "Q" ,
    EVENT_END_MARKET     = "M" ,
    EVENT_END_SYSTEM     = "E" ,
    EVENT_END_MESSAGES   = "C" ,

  } system_event_codes_e;

    //STOCK DIRECTORY MESSAGE

  typedef struct packed {
    logic [7:0]  dir_message_type;
    logic [15:0] dir_stock_locate;
    logic [15:0] dir_tracking_number;
    logic [47:0] dir_time_stamp;
    logic [63:0] dir_stock_symbol;
    logic [7:0]  dir_market_category;
    logic [7:0]  dir_financial_status_indicator;
    logic [31:0] dir_round_lot_size;
    logic [7:0]  dir_round_lots_only;
    logic [7:0]  dir_issue_classification;
    logic [7:0]  dir_authenticity;
    logic [7:0]  dir_short_sale_threshold_indicator;
    logic [7:0]  dir_ipo_flag;
    logic [7:0]  dir_LULUDReference_Price_Tier;
    logic [7:0]  dir_ETP_flag;
    logic [7:0]  dir_ETP_leverage_factor;
    logic [7:0]  dir_ETP_inverse_indicator;
  } Stock_Directory_Message;
  Stock_Directory_Message stock_directory_message;


  //ADD-ORDER NO MPID
    typedef struct packed {
    logic [7:0]  n_mpid_message_type;
    logic [15:0] n_mpid_stock_locate;
    logic [15:0] n_mpid_tracking_number;
    logic [47:0] n_mpid_time_stamp;
    logic [63:0] n_mpid_order_reference_number;
    logic [7:0]  n_mpid_buy_sell_indicator;
    logic [31:0] n_mpid_shares;
    logic [63:0] n_mpid_stock;
    logic [31:0] n_mpid_price;
    } Add_Order_NoMPID_Message;
  Add_Order_NoMPID_Message add_order_noMPID_message;

  //ADD-ORDER MPID
    typedef struct packed {
    logic [7:0]  mpid_message_type;
    logic [15:0] mpid_stock_locate;
    logic [15:0] mpid_tracking_number;
    logic [47:0] mpid_time_stamp;
    logic [63:0] mpid_order_reference_number;
    logic [7:0]  mpid_buy_sell_indicator;
    logic [31:0] mpid_shares;
    logic [63:0] mpid_stock;
    logic [31:0] mpid_price;
    logic [31:0] mpid_attribution;
    } Add_Order_MPID_Message;
  Add_Order_MPID_Message add_order_MPID_message;

    //ORDER EXECUTED
    typedef struct packed {
    logic [7:0]  order_exec_message_type;
    logic [15:0] order_exec_stock_locate;
    logic [15:0] order_exec_tracking_number;
    logic [47:0] order_exec_time_stamp;
    logic [63:0] order_exec_order_reference_number;
    logic [31:0] order_exec_shares;
    logic [63:0] order_exec_match_number;

    } Order_Executed_Message;
  Order_Executed_Message order_executed_message;

  //ORDER EXECUTED WITH PRICE
  typedef struct packed {
    logic [7:0]  order_exec_price_message_type;
    logic [15:0] order_exec_price_stock_locate;
    logic [15:0] order_exec_price_tracking_number;
    logic [47:0] order_exec_price_time_stamp;
    logic [63:0] order_exec_price_order_reference_number;
    logic [31:0] order_exec_price_shares;
    logic [63:0] order_exec_price_match_number;
    logic [7:0] order_exec_printable;
    logic [31:0] order_exec_price; //4dec
    } Order_Executed_With_Price_Message;
  Order_Executed_With_Price_Message order_executed_with_price_message;

  //ORDER CANCEL MESSAGE
  typedef struct packed {
    logic [7:0]  order_cancel_price_message_type;
    logic [15:0] order_cancel_price_stock_locate;
    logic [15:0] order_cancel_price_tracking_number;
    logic [47:0] order_cancel_price_time_stamp;
    logic [63:0] order_cancel_price_order_reference_number;
    logic [31:0] order_cancel_shares;
  } Order_Cancel_Message;
  Order_Cancel_Message order_cancel_message;

    //ORDER DELETE MESSAGE
  typedef struct packed {
    logic [7:0]  order_delete_message_type;
    logic [15:0] order_delete_stock_locate;
    logic [15:0] order_delete_tracking_number;
    logic [47:0] order_delete_time_stamp;
    logic [63:0] order_delete_order_reference_number;
  } Order_Delete_Message;
  Order_Delete_Message order_delete_message;

    //ORDER REPLACE MESSAGE
  typedef struct packed {
    logic [7:0]  order_replace_message_type;
    logic [15:0] order_replace_stock_locate;
    logic [15:0] order_replace_tracking_number;
    logic [47:0] order_replace_time_stamp;
    logic [63:0] order_replace_original_price_order_reference_number;
    logic [63:0] order_replace_new_price_order_reference_number;
    logic [31:0] order_replace_shares;
    logic [31:0] order_replace_price; //4dec
  } Order_Replace_Message;
  Order_Replace_Message order_replace_message;




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
              1,2: stock_directory_message.dir_stock_locate                     <= {stock_directory_message.dir_stock_locate[7:0], pcap_byte};
              3,4: stock_directory_message.dir_tracking_number                  <= {stock_directory_message.dir_tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: stock_directory_message.dir_time_stamp              <= {stock_directory_message.dir_time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: stock_directory_message.dir_stock_symbol <= {stock_directory_message.dir_stock_symbol[55:0], pcap_byte};
              19: stock_directory_message.dir_market_category                   <= pcap_byte;
              20: stock_directory_message.dir_financial_status_indicator        <= parse_financial_status(pcap_byte);
              21,22,23,24,25,25: stock_directory_message.dir_round_lot_size     <= {stock_directory_message.dir_round_lot_size[23:0], pcap_byte};
              26: stock_directory_message.dir_issue_classification              <= pcap_byte;
              27: stock_directory_message.dir_authenticity                      <= parse_authenticity(pcap_byte);
              28: stock_directory_message.dir_short_sale_threshold_indicator    <= parse_SST_Indicator(pcap_byte);
              29: stock_directory_message.dir_ipo_flag                          <= parse_IPO_Flag(pcap_byte);
              30: stock_directory_message.dir_LULUDReference_Price_Tier         <= parse_Price_Tier(pcap_byte);
              31: stock_directory_message.dir_ETP_flag                          <= parse_ETP_Flag(pcap_byte);
              32: stock_directory_message.dir_ETP_leverage_factor               <= pcap_byte;
              33: stock_directory_message.dir_ETP_inverse_indicator             <= parse_ETP_inverse_indicator(pcap_byte);
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 33) decoding_message <= 0;
          end
          else if(message_type == ADD_ORDER_NO_MPID) begin
            case(internal_byte_counter)
              1,2: add_order_noMPID_message.n_mpid_stock_locate                               <= {add_order_noMPID_message.n_mpid_stock_locate[7:0], pcap_byte};
              3,4: add_order_noMPID_message.n_mpid_tracking_number                            <= {add_order_noMPID_message.n_mpid_tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: add_order_noMPID_message.n_mpid_time_stamp                        <= {add_order_noMPID_message.n_mpid_time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: add_order_noMPID_message.n_mpid_order_reference_number <= {add_order_noMPID_message.n_mpid_order_reference_number[55:0], pcap_byte};
              19: add_order_noMPID_message.n_mpid_buy_sell_indicator                          <= pcap_byte;
              20,21,22,23: add_order_noMPID_message.n_mpid_shares                             <= {add_order_noMPID_message.n_mpid_shares[23:0], pcap_byte};
              24,25,26,27,28,29,30,31: add_order_noMPID_message.n_mpid_stock                  <= {add_order_noMPID_message.n_mpid_stock[55:0], pcap_byte};
              32,33,34,35: add_order_noMPID_message.n_mpid_price                              <= {add_order_noMPID_message.n_mpid_price[23:0], pcap_byte};
            endcase

          end

        end
      end


      end
    end
  end




endmodule