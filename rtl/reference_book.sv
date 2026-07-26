//NOTE CURRENTLY ASSUMING TICK SIZE IS ALWAYS 0.01
module reference_book import message_pckg::*; import toeplitz_hash::*; (
  input logic clk,
  input logic reset,
  input logic [7:0] message_type,
  input logic begin_processing,
  input Add_Order_NoMPID_Message add_order_noMPID_message,
  input Add_Order_MPID_Message add_order_MPID_message,
  input Order_Executed_Message order_executed_message,
  input Order_Executed_With_Price_Message order_executed_with_price_message,
  input Order_Cancel_Message order_cancel_message,
  input Order_Delete_Message order_delete_message,
  input Order_Replace_Message order_replace_message

);
/*ARCHITECTURE
  E.g. Add order comes in:
    Write order data output Add_Order_NoMPID_Message add_order_noMPID_message,
    Add shares to indexed by price in the order book

    Possibly start hash as soon as lower bytes enter


  Execute/Cancel/Delete
    Look up reference table to get stock locate, side, price, shares
    Find correct price level in order book
    Update shares remaining in reference table or delete order ref number etc
*/



//This method uses Cuckoo technique to have a max lookup time of 2-4 cycles,
//incase of misses



parameter ORDER_BOOK_ENTIRES = 1024;
parameter ORDER_BOOK_ENTRY_DEPTH = 12;
logic ref_order_book_1 [ORDER_BOOK_ENTIRES - 1: 0][ORDER_BOOK_ENTRY_DEPTH - 1 : 0];
logic ref_order_book_2  [ORDER_BOOK_ENTIRES - 1: 0][ORDER_BOOK_ENTRY_DEPTH - 1 : 0];
/*
 Bit 0 : valid
*/
parameter REF_FULL = 1;
 localparam MAX_EVICTS = 20;
 logic [7:0] evict_counter;

//evict chaining 
 typedef enum logic [2:0] {
   NONE,
   EVICT_1,
   EVICT_2,
   CHECK
 } state_t;
state_t evict_state;

logic [63:0] unhashed_ref;
logic [15:0] ref_index_1, ref_index_2, new_dummy_index_1, new_dummy_index_2;
logic [191:0] dummy_1, dummy_2;
assign new_dummy_index_1 = hash2(dummy[65:1]);
assign new_dummy_index_2 = hash1(dummy_2[65:1]);
assign ref_index_1 = hash1(unhashed_ref);
assign ref_index_2 = hash2(unhahsed_ref);


always_comb begin
   case (message_type)
     ADD_ORDER_NO_MPID: unhashed_ref = add_order_noMPID_message.order_reference_number;
     ADD_ORDER_MPID   : unhashed_ref = add_order_MPID_message.order_reference_number;
     ORDER_EXEC       : unhashed_ref = order_executed_message.order_reference_number;
     ORDER_EXEC_WITH_PRICE : unhashed_ref = order_executed_with_price_message.order_reference_number;
     ORDER_CANCEL     : unhashed_ref = order_cancel_message.order_reference_number;
     ORDER_DELETE     : unhashed_ref = order_delete_message.order_reference_number;
     ORDER_REPLACE    : unhashed_ref = order_replace_message.original_order_reference_number;
     default: unhashed_ref = 16'dx;
    endcase
end

always_ff @(posedge clk) begin
  if(reset) begin
    ref_order_book_1 <= 0;
    ref_order_book_2 <= 0;
    dummy <= 0;
    start_evict_chain <= 0;
  end
  else if (begin_processing) begin
    case(message_type)
      ADD_ORDER_NO_MPID: begin
        if(ref_order_book_1[ref_index_1][0] == !REF_FULL) begin // insert
          ref_order_book_1[ref_index_1] <= {add_order_noMPID_message.order_reference_number,REF_FULL};
        end
        else if(ref_order_book_1[ref_index_1][0] == REF_FULL && ref_order_book_2[ref_index_2][0] == !REF_FULL) begin
          ref_order_book_2[ref_index_2][0] <= {add_order_noMPID_message.order_reference_number, REF_FULL};
        end
        else begin
          dummy <= ref_order_book_1[ref_index_1];
          ref_order_book_1[ref_index_1] <= {add_order_noMPID_message.order_reference_number, REF_FULL};
          evict_state <= EVICT_1;
          evict_counter <= 0;
        end
      end
      ADD_ORDER_MPID: begin
        if(ref_order_book_1[ref_index_1][0] == !REF_FULL) begin // insert
          ref_order_book_1[ref_index_1] <= {add_order_MPID_message.order_reference_number,REF_FULL};
        end
        else if(ref_order_book_1[ref_index_1][0] == REF_FULL && ref_order_book_2[ref_index_2][0] == !REF_FULL) begin
          ref_order_book_2[ref_index_2][0] <= {add_order_MPID_message.order_reference_number, REF_FULL};
        end
        else begin
          dummy <= ref_order_book_1[ref_index_1];
          ref_order_book_1[ref_index_1] <= {add_order_MPID_message.order_reference_number, REF_FULL};
          evict_state <= EVICT_1;
          evict_counter <= 0;
        end
      end
    endcase
  end

end


//Evict chain handler
always_ff @(posedge clk) begin
  if(reset) begin
    evict_state <= NONE;
  end
  else if (evict_counter < 20) begin
    case(evict_state)
      EVICT_1: begin
        if(ref_order_book_2 == REF_FULL) begin
          dummy_2 <= ref_order_book_2[new_dummy_index_1];
          ref_order_book_2[dummy_index_1] <= dummy_1;
          evic_counter <= evict_counter + 1;
        end
        else evict_state <= NONE;
      end
      EVICT_2: begin
        if(ref_order_book_1 == REF_FULL) begin
          dummy_1 <= ref_order_book_1[new_dummy_index_2];
          ref_order_book_1[new_dummy_index_2] <= dummy_2;
          evic_counter <= evict_counter + 1;
        end
        else evict_state <= NONE;
      end
      default: evict_state <= NONE;
    endcase
  end
  else if(evict_counter == 20) begin
    //TODO SEND A REMOVE ORDER TO THE ORDER BOOK;
    $display("MAX EVICTS REACHED");
  end
end



//Add the data
always_ff @(posedge clk) begin
  if(msg_done) begin
    case(msg_type)
      ADD_ORDER_MPID: begin
        if(ref_order_book_1[ref_index_1][65:0] == add_order_MPID_message.order_reference_number) begin

        end
        else begin

        end
      end
      ADD_ORDER_NO_MPID: begin
        if(ref_order_book_1[ref_index_1][65:0] == add_order_MPID_message.order_reference_number) begin

        end
        else begin

        end
      end


    endcase



  end

end
endmodule
