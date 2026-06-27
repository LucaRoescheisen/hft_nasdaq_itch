import message_pckg::*;
//NOTE CURRENTLY ASSUMING TICK SIZE IS ALWAYS 0.01
module order_book(
  input logic clk,
  input logic reset,
  input logic message_type,
  input logic price,
  input logic quantity,
  input logic order_id,
  input logic new_instr,
  input logic buy_sell_indicator,
  input logic first_instr,
  output logic  should_order
);
/*ARCHITECTURE
  E.g. Add order comes in:
    Write order details into the reference table which is keyed by order_ref_num
    Add shares to indexed by price in the order book

  Execute/Cancel/Delete
    Look up reference table to get stock locate, side, price, shares
    Find correct price level in order book
    Update shares remaining in reference table or delete order ref number etc
*/


endmodule
