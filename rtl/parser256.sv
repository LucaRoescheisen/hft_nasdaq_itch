module parser256 import message_pckg ::*;(
  input clk,
  input reset,
  input [255:0] bus,
  input rx_sof,
  input rx_eof,
  input [31:0] rx_keep,
  input rx_valid
 



  );

  parameter int NO_MPID_OFFSET = (36) * BYTE; 


  parameter int BYTE = 8;
  parameter int MSG_TYPE_OFFSET = 4 * BYTE;



  logic [255:0] bus_copy;
  logic [511:0] barrel_shifter;

  //SOF PROPERTIES
  logic [7:0] sof_msg_type;
  
  always_comb begin
    sof_msg_type = rx_sof ? bus[0 +: BYTE - 1] : 0;
    case(sof_msg_type)
      ADD_ORDER_NO_MPID : sof_offset = NO_MPID_OFFSET;

    endcase
  end



  always_ff @(posedge clk) begin
    if(reset) begin
      barrel_shifter <= 0;
      bus_copy <= 0;
    end 
    else begin 
      if(sof) begin
        

      end
      bus_copy <= {bus, {0'b256}};




    end
  end

  endmodule
