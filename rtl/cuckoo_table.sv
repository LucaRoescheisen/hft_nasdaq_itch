module cuckoo_table import message_pckg::*; import toeplitz_hash::*; #(
  parameter int BUCKET_SIZE = 4,
  parameter int BUCKET_SIZE_SEG = 4,
  parameter int OFFSET = 64
  )(
  input clk,
  input reset,
  input [7:0] msg_type,
  input we,
  input Add_Order_NoMPID_Message add_order_noMPID_message,
  input Add_Order_MPID_Message add_order_MPID_message,
  input Order_Executed_Message order_executed_message,
  input Order_Executed_With_Price_Message order_executed_with_price_message,
  input Order_Cancel_Message order_cancel_message,
  input Order_Delete_Message order_delete_message,
  input Order_Replace_Message order_replace_message,
  input Stock_Directory_Message stock_directory_message,
  input System_Event_Message system_event_message

  
    ,output [15:0] collisions
    ,output [31:0] inserts_1
    ,output [31:0] inserts_2

  );


 // First 4 bits represent whether the slot in the bucket is full (1) or empty
 parameter BUCKET_WIDTH = BUCKET_SIZE * 64 - 1 + BUCKET_SIZE_SEG;
  logic [BUCKET_WIDTH:0] tb_1 [1023:0];
  logic [BUCKET_WIDTH:0] tb_2 [1023:0];
  
  logic [9:0] h1;
  logic [9:0] h2; 
  logic [9:0] h1_r;
  logic [9:0] h2_r;
  
  //Used for replace
  logic [9:0] h1_new;
  logic [9:0] h2_new;

  logic[BUCKET_WIDTH:0] bucket_1;
  logic[BUCKET_WIDTH:0] bucket_2;
  
  logic [63:0] ref_num;
  logic [63:0] ref_num_r;

  logic we_r;
  logic [7:0] msg_type_r;

  always_comb begin
    case(msg_type)
      "A": begin
        h1 = hash1(add_order_noMPID_message.order_reference_number);
        h2 = hash2(add_order_noMPID_message.order_reference_number);
        ref_num = add_order_noMPID_message.order_reference_number;
        end
      "F": begin
        h1 = hash1(add_order_MPID_message.order_reference_number);
        h2 = hash2(add_order_MPID_message.order_reference_number);
        ref_num = add_order_MPID_message.order_reference_number;
      end
      "D": begin
        h1 = hash1(order_delete_message.order_reference_number);
        h2 = hash2(order_delete_message.order_reference_number);
        ref_num = order_delete_message.order_reference_number;
      end
      "U": begin
        h1 = hash1(order_replace_message.original_order_reference_number);
        h2 = hash2(order_replace_message.original_order_reference_number);
        h1_new = hash1(order_replace_message.new_order_reference_number);
        h2_new = hash2(order_replace_message.new_order_reference_number);
      end
      "E": begin
        h1 = hash1(order_executed_message.order_reference_number);
        h2 = hash2(order_executed_message.order_reference_number);
        ref_num = order_executed_message.order_reference_number;
      end
      "C": begin
        h1 = hash1(order_executed_with_price_message.order_reference_number);
        h2 = hash2(order_executed_with_price_message.order_reference_number);
        ref_num = order_executed_with_price_message.order_reference_number;
      end
      "X": begin
        h1 = hash1(order_cancel_message.order_reference_number);
        h2 = hash2(order_cancel_message.order_reference_number);
        ref_num = order_cancel_message.order_reference_number;
      end
      default: begin
        h1 = 0;
        h2 = 0;
        ref_num = 0;
      end

    endcase
  end

  
  always_ff @(posedge clk) begin
    bucket_1 <= tb_1[h1];
    bucket_2 <= tb_2[h2];
    ref_num_r <= ref_num;
    we_r <= we;
    msg_type_r <= msg_type;
    h1_r <= h1;
    h2_r <= h2;
  end
  

  // INSERT LOGIC
logic [3:0] b1_slots, b2_slots;
logic [2:0] b1_first_free_slot, b2_first_free_slot;
logic [2:0] b1_size, b2_size;

always_comb begin
  b1_slots = bucket_1[3:0];
  b2_slots = bucket_2[3:0];

  b1_first_free_slot = (b1_slots[0] == 0) ? 1 :
                        (b1_slots[1] == 0) ? 2 :
                        (b1_slots[2] == 0) ? 3 :
                        (b1_slots[3] == 0) ? 4 : 0;

  b2_first_free_slot = (b2_slots[0] == 0) ? 1 :
                        (b2_slots[1] == 0) ? 2 :
                        (b2_slots[2] == 0) ? 3 :
                        (b2_slots[3] == 0) ? 4 : 0;

  b1_size = {2'b0, b1_slots[0]} + {2'b0, b1_slots[1]} + {2'b0, b1_slots[2]} + {2'b0, b1_slots[3]};
  b2_size = {2'b0, b2_slots[0]} + {2'b0, b2_slots[1]} + {2'b0, b2_slots[2]} + {2'b0, b2_slots[3]};
end



  always_ff @(posedge clk) begin
    if(reset) begin
      collisions <= 0;
      inserts_1 <= 0;
      inserts_2 <= 0;
    end
    else begin
      
      if(b1_first_free_slot == 0 && b2_first_free_slot == 0) begin
        collisions += 1;
      end
      else if(msg_type_r == "A" || msg_type_r == "F") begin
        if((b1_size <= b2_size) && we_r) begin //Bucket 1 smaller
          case(b1_first_free_slot)
            3'b001 : begin 
              tb_1[h1_r][BUCKET_SIZE_SEG +: OFFSET] <= ref_num_r;
              tb_1[h1_r][0 +: BUCKET_SIZE_SEG] <= b1_slots | 4'b0001;
            inserts_1 += 1;
            end
            3'b010 : begin 
              tb_1[h1_r][BUCKET_SIZE_SEG+OFFSET +: OFFSET] <= ref_num_r;
              tb_1[h1_r][0 +: BUCKET_SIZE_SEG] <= b1_slots | 4'b0010;
            inserts_1 += 1;
            end
            3'b011 : begin 
              tb_1[h1_r][BUCKET_SIZE_SEG+OFFSET*2 +: OFFSET] <= ref_num_r;
              tb_1[h1_r][0 +: BUCKET_SIZE_SEG] <= b1_slots | 4'b0100;
            inserts_1 += 1;
            end
            3'b100 : begin
              tb_1[h1_r][BUCKET_SIZE_SEG+OFFSET*3 +: OFFSET] <= ref_num_r;
              tb_1[h1_r][0 +: BUCKET_SIZE_SEG] <= b1_slots | 4'b1000;
            inserts_1 += 1;
            end
            endcase
        end
        else if((b1_size > b2_size) && we_r) begin //Bucket 2 smaller
          case(b2_first_free_slot)
            3'b001 : begin 
              tb_2[h2_r][BUCKET_SIZE_SEG +: OFFSET] <= ref_num_r;
              tb_2[h2_r][0 +: BUCKET_SIZE_SEG] <= b2_slots | 4'b0001;
            end
            3'b010 :  begin 
              tb_2[h2_r][BUCKET_SIZE_SEG+OFFSET +: OFFSET] <= ref_num_r;
              tb_2[h2_r][0 +: BUCKET_SIZE_SEG] <= b2_slots | 4'b0010;
            end
            3'b011 : begin 
              tb_2[h2_r][BUCKET_SIZE_SEG+OFFSET*2 +: OFFSET] <= ref_num_r;
              tb_2[h2_r][0 +: BUCKET_SIZE_SEG] <= b2_slots | 4'b0100;
            end
            3'b100 : begin
              tb_2[h2_r][BUCKET_SIZE_SEG+OFFSET*3 +: OFFSET] <= ref_num_r;
              tb_2[h2_r][0 +: BUCKET_SIZE_SEG] <= b2_slots | 4'b1000;
            end
            endcase
            inserts_2 += 1;
        end
      end
    end
  end





  //REMOVE LOGIC

  parameter int INITIAL_OFFSET = BUCKET_SIZE_SEG;
  parameter int FULL = 1;
  parameter int EMPTY = 0;
 // logic in_tb_1 = bucket_1[0] == FULL ? (ref_num == bucket_1[INITIAL_OFFSET:OFFSET]);



endmodule
