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
  logic [31:0] byte_counter;
  logic [31:0] payload_len;
  logic [31:0] packet_end;

  //MoldUDP64
  logic [79:0] session;
  logic [63:0] sequence_number;
  logic [15:0] message_count; //if message_count == 0xFFFF then it is a heartbeat and rest of packet can be ignored

  always_ff @(clk) begin
    if(reset) begin
      byte_counter <= 0;
      payload_len  <= 0;
      packet_end   <=  { 31{1'b1} };
    end else begin
      if(byte_counter == packet_end) begin  //Reset byte counter at end of packet
        byte_counter <= 0;
        payload_len  <= 0;
        packet_end   <=  { 31{1'b1} };
      end else begin
        byte_counter <= byte_counter + 1;

        //Generate payload length and packet end
        case (byte_counter)
          42 : payload_len[15:8] <= pcap_byte; //Get length of payload
          43 : payload_len[7:0]  <= pcap_byte;
          44 : payload_len[15:8] <= payload_len[15:8] - 8; //Since UDP counts part of payload we minus 8
          45 : packet_end <= byte_counter + packet_end;
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
          56 : sequence_number[55:48] <= pcap_byte;
          56 : sequence_number[47:40] <= pcap_byte;
          56 : sequence_number[39:32] <= pcap_byte;
          60 : sequence_number[31:24] <= pcap_byte;
          61 : sequence_number[31:24] <= pcap_byte;
          62 : sequence_number[23:16] <= pcap_byte;
          63 : sequence_number[15:8]  <= pcap_byte;
          64 : sequence_number[7:0]   <= pcap_byte;
          65 : message_count[15:8]  <= pcap_byte;
          66 : message_count[7:0]   <= pcap_byte;
        endcase

        if(message_count != 16'hffff || byte_counter > 66) begin //Make sure it is not a heartbeat


        end


      end
    end
  end


endmodule