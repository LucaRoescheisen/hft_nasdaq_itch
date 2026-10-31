module parser256 import message_pckg ::*;(
  input clk,
  input reset,
  input [255:0] bus,
  input rx_sof,
  input rx_eof,
  input [31:0] rx_keep,
  input rx_valid
 



  );
  parameter int ASM_LINE_LEN = 1024;


  logic [255:0] bus_copy;

  logic [ASM_LINE_LEN - 1:0] assembly_line;
  logic [ASM_LINE_LEN - 1:0] next_asm_line;
  logic [9:0] front_ptr;


  logic [5:0] valid_bytes_w;
  logic [5:0] valid_bytes_r;

  logic[9:0] left_over;

  always_comb begin
    valid_bytes_w = $countones(rx_keep) << 3; // Multiply by 8

    for (int i = 0; i < 32; i++) begin
        if (i < valid_bytes_w)
            next_asm_line[(front_ptr + i)*8 +: 8] = bus[i*8 +: 8];
    end

  end
  
//Insert into asm line
  always_ff @(posedge clk) begin
    if(reset) begin
      bus_copy <=  0;
      valid_bytes <= 0;
    end 
    else begin 
      valid_bytes_r <= valid_bytes_w;
      front_ptr <= front_ptr + valid_bytes_w;
      assembly_line <= next_asm_line;
    end
  end


  //Remove messages from asm line:
  
  always_comb begin
    msg_len = assembly_line[0:2]
    
  end


  always_ff @(posedge clk) begin
    if(reset) begin

    end
    else begin
    
    end

  end



  endmodule
