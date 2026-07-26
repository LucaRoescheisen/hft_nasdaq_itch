//NOTE CURRENTLY ASSUMING TICK SIZE IS ALWAYS 0.01
module order_book import message_pckg::*; (
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


logic [2047:0] freelist [11:0];
initial begin
  $readmemh("python_scripts/generate_2047.mem", freelist);
end


logic [2047:0] static_items [87:0];


parameter ORDER_BOOK_ENTIRES = 1024;
parameter ORDER_BOOK_ENTRY_DEPTH = 11;
logic ref_order_book [ORDER_BOOK_ENTIRES - 1: 0][ORDER_BOOK_ENTRY_DEPTH - 1 : 0];
logic [15:0] ref_index;
always_ff @(posedge clk) begin
  if(reset) begin
    ref_order_book <= 0;
    ref_index <= 0;
  end else if (begin_processing) begin
    case (message_type)
      ADD_ORDER_NO_MPID: ref_index <= add_order_noMPID_message.order_reference_number[15:0];
      ADD_ORDER_MPID   : ref_index <= add_order_MPID_message.order_reference_number[15:0];
      ORDER_EXEC       : ref_index <= order_executed_message.order_reference_number[15:0];
      ORDER_EXEC_WITH_PRICE : ref_index <= order_executed_with_price_message.order_reference_number[15:0];
      ORDER_CANCEL     : ref_idnex <= order_cancel_message.order_reference_number[15:0];
      ORDER_DELETE     : ref_index <= order_delete_message.order_reference_number[15:0];
      ORDER_REPLACE    : ref_index <= order_replace_message.original_order_reference_number[15:0];
    endcase
  end

end
endmodule
