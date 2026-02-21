//NOTE ON CURRENT DESIGN : ASSUMPTION  CLK SPEED == INCOMING BYTE SEEED (will update later for more realistic results/methodologies)

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
    STOCK_DIR,
    ADD_ORDER_NO_MPID,
    ADD_ORDER_MPID,
    ORDER_EXEC,
    ORDER_CANCEL,
    ORDER_DELETE,
    ORDER_REPLACE,
    TRADE
  } message_states;

  typedef enum logic [7:0] {
    EVENT_START_MESSAGES = "O" ,
    EVENT_START_SYSTEM   = "S" ,
    EVENT_START_MARKET   = "Q" ,
    EVENT_END_MARKET     = "M" ,
    EVENT_END_SYSTEM     = "E" ,
    EVENT_END_MESSAGES   = "C" ,

  } system_event_codes;


  typedef enum logic [2:0] {
    SYSTEM_EVENT_MESSAGE_LENGTH  = 12,
    ...

  } message_lengths;



  typedef struct packed {
    logic [3:0] sys_message_type;
    logic [7:0] sys_stock_locate;
    logic [7:0] sys_tracking_number;
    logic [47:0] sys_time_stamp;
    logic [3:0] sys_event_code;
  } System_Event_Message;
  System_Event_Message system_event_message;

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
          42 : payload_len[15:8] <= pcap_byte; //Get length of payload
          43 : payload_len[7:0]  <= pcap_byte;
          44 : payload_len[15:8] <= payload_len[15:8] - 8; //Since UDP counts part of payload we minus 8
          45 : packet_end <= global_byte_counter + packet_end;
          46 : session[79:72] <= pcap_byte;
          47 : session[71:64] <= pcap_byte;
          48 : session[63:56] <= pcap_byte;
          49 : session[55:48] <= pcap_byte;
          50 : session[47:40] <= pcap_byte;
          51 : session[39:32] <= pcap_byte;
          52 : session[31:24] <= pcap_byte;
          53 : session[23:16] <= pcap_byte;
          54 : session[15:8]  <= pcap_byte;
          55 : session[7:0]   <= pcap_byte;
          56 : sequence_number[63:56] <= pcap_byte;
          57 : sequence_number[55:48] <= pcap_byte;
          58 : sequence_number[47:40] <= pcap_byte;
          59 : sequence_number[39:32] <= pcap_byte;
          60 : sequence_number[31:24] <= pcap_byte;
          61 : sequence_number[31:24] <= pcap_byte;
          62 : sequence_number[23:16] <= pcap_byte;
          63 : sequence_number[15:8]  <= pcap_byte;
          64 : sequence_number[7:0]   <= pcap_byte;
          65 : message_count[15:8]    <= pcap_byte;
          66 : message_count[7:0]     <= pcap_byte;

        endcase

        if(message_count != 16'hffff || global_byte_counter > 66) begin //Make sure it is not a heartbeat
          //Event System Message (12 bytes)
          if(pcap_byte == SYSTEM && !decoding_message) begin
            internal_byte_counter <= 1;
            decoding_message <= 1;
            system_event_message.sys_message_type <= SYSTEM;
            message_type <= SYSTEM;
          end

          if(message_type == SYSTEM && decoding_message) begin
            internal_byte_counter <= internal_byte_counter + 1;
            case(internal_byte_counter)
              1:  system_event_message.sys_stock_locate[15:8]    <= pcap_byte;
              2:  system_event_message.sys_stock_locate[7:0]     <= pcap_byte;
              3:  system_event_message.sys_tracking_number[15:8] <= pcap_byte;
              4:  system_event_message.sys_tracking_number[7:0]  <= pcap_byte;
              5:  system_event_message.sys_time_stamp[47:40]     <= pcap_byte;
              6:  system_event_message.sys_time_stamp[39:32]     <= pcap_byte;
              7:  system_event_message.sys_time_stamp[31:24]     <= pcap_byte;
              8:  system_event_message.sys_time_stamp[23:16]     <= pcap_byte;
              9:  system_event_message.sys_time_stamp[15:8]      <= pcap_byte;
              10: system_event_message.sys_time_stamp[7:0]       <= pcap_byte;
              11: system_event_message.sys_event_code[7:0]       <= pcap_byte;
            endcase
            if(internal_byte_counter == 11) decoding_message <= 0;
          end

        end
      end


      end
    end
  end


endmodule