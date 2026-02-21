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
    SYSTEM = "S",
    STOCK_DIR = "R",
    ADD_ORDER_NO_MPID,
    ADD_ORDER_MPID,
    ORDER_EXEC,
    ORDER_CANCEL,
    ORDER_DELETE,
    ORDER_REPLACE,
    TRADE
  } message_states;



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
          42,43: payload_len <= {payload_len[7:0], pcap_byte}; //Get length of payload
          44: payload_len[15:8] <= payload_len[15:8] - 8; //Since UDP counts part of payload we minus 8
          45: packet_end <= global_byte_counter + packet_end;
          46,47,48,49,50,51,52,53,54,55: session <= {session[71:0], pcap_byte};
          56,57,58,59,60,61,62,63,64: sequence_number <= {sequence_number[55:0], pcap_byte};
          65,66: message_count <= {message_count[7:0], pcap_byte};


        endcase

        if(message_count != 16'hffff || global_byte_counter > 66) begin //Make sure it is not a heartbeat
          //Event System Message (12 bytes)
          if(pcap_byte == SYSTEM && !decoding_message) begin
            internal_byte_counter <= 1;
            decoding_message <= 1;
            system_event_message.sys_message_type <= SYSTEM;
            message_type <= SYSTEM;
          end
          if(pcap_byte == STOCK_DIR && !decoding_message) begin
            internal_byte_counter <= 1;
            decoding_message <= 1;
            stock_directory_message.dir_message_type <= STOCK_DIR;
            message_type <= STOCK_DIR;
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

          if(message_type == STOCK_DIR && decoding_message) begin
            case(internal_byte_counter)
              1,2: stock_directory_message.dir_stock_locate <= {stock_directory_message.dir_stock_locate[7:0], pcap_byte};
              3,4: stock_directory_message.dir_tracking_number <= {stock_directory_message.dir_tracking_number[7:0], pcap_byte};
              5,6,7,8,9,10: stock_directory_message.dir_time_stamp <= {stock_directory_message.dir_time_stamp[39:0], pcap_byte};
              11,12,13,14,15,16,17,18: stock_directory_message.dir_stock_symbol <= {stock_directory_message.dir_stock_symbol[55:0], pcap_byte};
              19: stock_directory_message.dir_market_category  <= pcap_byte;
              20: stock_directory_message.dir_financial_status_indicator  <= parse_financial_status(pcap_byte);
              21,22,23,24,25,25: stock_directory_message.dir_round_lot_size <= {stock_directory_message.dir_round_lot_size[23:0], pcap_byte};
              26: stock_directory_message.dir_issue_classification <= pcap_byte;
              27: stock_directory_message.dir_authenticity <= parse_authenticity(pcap_byte);
              28: stock_directory_message.dir_short_sale_threshold_indicator <= parse_SST_Indicator(pcap_byte);
              29: stock_directory_message.dir_ipo_flag <= parse_IPO_Flag(pcap_byte);
              30: stock_directory_message.dir_LULUDReference_Price_Tier <= parse_Price_Tier(pcap_byte);
              31: stock_directory_message.dir_ETP_flag <= parse_ETP_Flag(pcap_byte);
              32: stock_directory_message.dir_ETP_leverage_factor <= pcap_byte;
              33: stock_directory_message.dir_ETP_inverse_indicator <= parse_ETP_inverse_indicator(pcap_byte);
            endcase
            internal_byte_counter <= internal_byte_counter + 1;
            if(internal_byte_counter == 33) decoding_message <= 0;
          end


        end
      end


      end
    end
  end


endmodule