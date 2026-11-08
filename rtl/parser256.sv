module parser256 import message_pckg ::*;(
  input clk,
  input reset,
  input [255:0] bus,
  input rx_sof,
  input rx_eof,
  input [31:0] rx_keep,
  input rx_valid,
 

  output logic [2:0] messages_processed

  );
  parameter int ASM_LINE_LEN = 1024;



  logic [ASM_LINE_LEN - 1:0] assembly_line;
  logic [ASM_LINE_LEN - 1:0] next_asm_line;
  logic [9:0] front_ptr;
  logic [9:0] rear_ptr; 
  logic rx_sof_reg;

  logic [9:0] old_rear_ptr;

  logic [5:0] valid_bytes_w;
  logic [5:0] valid_bytes_r;


  //For each valid byte from rx_keep store these bytes in a separate buffer
  always_comb begin
    valid_bytes_w = $countones(rx_keep); // Multiply by 8
    next_asm_line = assembly_line;
    for (int i = 0; i < 32; i++) begin
        if (i < valid_bytes_w)
            next_asm_line[(({22'b0,rear_ptr}) + i * 8) +: 8] = bus[i*8 +: 8];
    end

  end
  
//Insert into asm line
  always_ff @(posedge clk) begin
    if(reset) begin
      assembly_line <= 0;
      rx_sof_reg <= 0;
      rear_ptr <= 0;
      old_rear_ptr <= 0;
      valid_bytes_r <= 0;
    end 
    else begin 
      if(rx_valid) begin
        rx_sof_reg <= rx_sof;
        valid_bytes_r <= valid_bytes_w;
        rear_ptr <= ((rear_ptr +  valid_bytes_w *8)) & 10'd1023;
        assembly_line <= next_asm_line;
        old_rear_ptr <= rear_ptr;
      end
    end
  end


  //Remove messages from asm line:
  logic[15:0] msg_len_1;
  logic[15:0] msg_len_2;
  logic[15:0] offset_to_msg_2;

  logic [10:0] front_to_rear_len;
  logic [2:0] number_of_extracts;
  logic[15:0] inter;
  logic [15:0] b_test;

  always_comb begin
    front_to_rear_len = ((rear_ptr <front_ptr) ? 10'd1023 - (front_ptr -rear_ptr) : rear_ptr - front_ptr);

b_test = 
                {{assembly_line[front_ptr +: 8]},{assembly_line[front_ptr+8 +: 8]}} ;
    msg_len_1 =
           
                {{assembly_line[front_ptr +: 8]},{assembly_line[front_ptr+8 +: 8]}} * 8;
    offset_to_msg_2 = ({5'b0, front_ptr} + msg_len_1) & 16'd1023; //+16 because of msg len bytes
    inter = msg_len_1 + offset_to_msg_2;

    if (inter+16 < {5'b0, front_to_rear_len}) begin
        msg_len_2 = (inter == 0) ? {{assembly_line[1015:1008]},{assembly_line[1023: 1016]}} *8              :
                    inter == 8 ? {{assembly_line[1023:1016]},{assembly_line[rear_ptr -: 8]}} * 8            :
                  {{assembly_line[inter[9:0] +: 8]},{assembly_line[inter[9:0]+8 +: 8]}} * 8;
    end
    else begin
      msg_len_2 = 1;
    end
    

    if(front_to_rear_len == 0) begin
      number_of_extracts = 0;
    end
    else begin
    number_of_extracts = front_to_rear_len < msg_len_1[10:0]               ? 0 :
                         (front_to_rear_len < (msg_len_1[10:0] + msg_len_2[10:0])) & (front_to_rear_len >= msg_len_1[10:0]) & (msg_len_2 < 100) ? 2 : 1;
    end
  end
  
//Extraction
  always_ff @(posedge clk) begin
    if(reset) begin
      front_ptr <= 0;
      
    end
    else begin
      messages_processed <= number_of_extracts;
      if(number_of_extracts == 1) begin
        front_ptr <= front_ptr + msg_len_1[9:0]+16;

      end
      else if (number_of_extracts == 2) begin
        front_ptr <= front_ptr + msg_len_1[9:0] +16;
      end

    end

  end



  endmodule
