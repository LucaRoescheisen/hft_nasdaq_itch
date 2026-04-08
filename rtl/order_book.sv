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
/*Pipeline Process
  Cycle 1: Check if order_info exists. If not probe until you find a spot
  Cycle 2: Open either bid or ask levels and based on order_info inject it in.
  Cycle 3: process the information

*/
localparam TICK_SIZE = 10;
localparam TICK_FEED = 10_000;


function longint unsigned hash_func (input logic[63:0] order_id); //hash function
  begin
  return order_id[12:0] ^ 63'hd6e8;
  end
endfunction


typedef struct packed {
    logic [31:0] price;
    logic [31:0] quantity;
    logic [15:0] order_count;
} level_t;

level_t bid_levels[64]  = '{default:'0};
level_t ask_levels[64]  = '{default:'0};


typedef struct packed {
  logic [63:0] order_id;
  logic [31:0] remaining_qty;
  logic [31:0] price;
} order_info_t;

order_info_t order_info[8191:0] = '{default:'0};
initial begin


end
logic [5:0] book_bid_origin_ptr; //Points to lowest bid offer
logic [5:0] book_ask_origin_ptr; //Points to lowest ask offer


logic [12:0] hashed_order_id; //Purely combinational
assign hashed_order_id = hash_func(order_id);
logic [5:0] bias;


logic move_to_next_cell;
//For updating order_info
always_ff @(clk) begin
  if(reset) begin
    book_bid_origin_ptr <= 0;
    book_ask_origin_ptr <= 0;
    bias                <= 0;
  end
  if(new_instr && (message_type == ADD_ORDER_NO_MPID || message_type == ADD_ORDER_MPID) && buy_sell_indicator == BUY) begin
    //For new order
    if(order_info[hashed_order_id + bias].order_id != 0) begin //Collision occured, move to next cell
      bias <= bias + 1;
    end
    else begin
      order_info[hashed_order_id + bias].order_id      <= order_id;
      order_info[hashed_order_id + bias].remaining_qty <= quantity;
      order_info[hashed_order_id + bias].price         <= price;
    end
  end
end



logic[31:0] min_price_bid;
logic[31:0] max_price_bid;
logic [5:0] index_bid;

logic[31:0] min_price_ask;
logic[31:0] max_price_ask;
logic [5:0] index_ask;

logic new_lowest;
logic new_highest;
logic calculated_index_bid;

logic is_bid, is_ask;

logic [15:0] calculated_index_ask;

//Updates  bid books
always_ff @(posedge clk) begin
  if(reset) begin
    min_price_bid <= 0;
    new_lowest <= 0;
    calculated_index_bid <= 0;
  end
  else begin

    if(new_instr && (message_type == ADD_ORDER_NO_MPID || message_type == ADD_ORDER_MPID)) begin
      is_bid <= (buy_sell_indicator == BUY);
      is_ask <= (buy_sell_indicator == SELL);
      if(is_bid) begin



      end
      if(is_ask) begin


      end
    end




    min_price_bid <= bid_levels[book_bid_origin_ptr];
    max_price_bid <= min_price_bid + 63 * TICK_SIZE;
    if(new_lowest) begin
      book_bid_origin_ptr <= index_bid;
      new_lowest <= 0;
    end
    if(new_highest) begin
      book_ask_origin_ptr <= index_ask;
      new_highest <= 0;
    end

  //stage 1
    if(new_instr && (message_type == ADD_ORDER_NO_MPID || message_type == ADD_ORDER_MPID) && buy_sell_indicator == BUY) begin
      if(first_instr) begin
        bid_levels[0].price <= price;
        bid_levels[0].quantity <= quantity;
        bid_levels[0].order_count <= bid_levels[0].order_count + 1;
      end
      else begin
        if(price >= min_price_bid && price <= min_price_bid) begin
          index_bid <= (price - min_price_bid) >> 7;
        end
        else if(price <= min_price_bid) begin
          index_bid <= (( $signed(price) - $signed(min_price_bid) + 64) >> 7) & 6'b111111;
          new_lowest <= 1;
        end
        calculated_index_bid <= 1;
      end
    end
    else if(new_instr && (message_type == ADD_ORDER_NO_MPID || message_type == ADD_ORDER_MPID) && buy_sell_indicator == SELL) begin
      if(first_instr) begin
        ask_levels[0].price <= price;
        ask_levels[0].quantity <= quantity;
        ask_levels[0].order_count <= ask_levels[0].order_count + 1;
      end
      else begin
        if(price >= max_price_ask) begin
          index_ask <= (max_price_ask - price) >> 7;
          new_highest <= 1;
        end
        else if(price <= max_price_ask) begin
          index_ask <= (( $signed(price) - $signed(max_price_ask) + 64) >> 7) & 6'b111111;
        end
        calculated_index_ask <= 1;
      end
    end


//stage 2, update value at the index
  if(calculated_index_ask) begin
    ask_levels[index_ask].price <= price;
    ask_levels[index_ask].quantity <= ask_levels[index_ask].quantity + quantity;
    ask_levels[index_ask].order_count <= ask_levels[index_ask].order_count + 1;
    calculated_index_ask <= 0;
  end
  else if(calculated_index_bid) begin
    bid_levels[index_bid].price <= price;
    bid_levels[index_bid].quantity <= bid_levels[index_bid].quantity + quantity;
    bid_levels[index_bid].order_count <= bid_levels[index_bid].order_count + 1;
    calculated_index_bid <= 0;
  end
  end
end



//Check for buy/sell
always @(posedge clk) begin
  if(reset) begin
    should_order <= 0;
  end
  else begin
    if(ask_levels[book_ask_origin_ptr] > bid_levels[book_bid_origin_ptr])begin
      if(ask_levels[book_ask_origin_ptr].quantity >= bid_levels[book_bid_origin_ptr].quantity) begin
        should_order <= 1;
      end
    end
  end
end




endmodule