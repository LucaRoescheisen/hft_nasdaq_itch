import stock_dir_pckg::*;
//NOTE CURRENTLY ASSUMING TICK SIZE IS ALWAYS 0.01
module order_book(
  input clk,
  input reset
  input message_type,
  input price,
  input quantity,
  input order_id,
  input new_instr
);
/*Pipeline Process
  Cycle 1: Check if order_info exists. If not probe until you find a spot
  Cycle 2: Open either bid or ask levels and based on order_info inject it in.
  Cycle 3: process the information

*/
localparam TICK_SIZE = 10;
localparam TICK_FEED = 10_000;


function longint unsigned hash_func (logic[63:0] order_id); //hash function
  return order_id[12:0] ^ 63'hd6e8;
endfunction


typedef struct packed {
    logic [31:0] price,
    logic [31:0] quantity,
    logic [15:0] order_count
} level_t;

level_t bid_levels[64]  = '{default:'0};;
level_t ask_levels[64]  = '{default:'0};;


typedef struct packed {
  logic [63:0] order_id,
  logic [31:0] remaining_qty,
  logic [31:0] price
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
always @(posedge clk) begin
  if(reset) begin
    book_bid_origin_ptr <= 0;
    book_ask_origin_ptr <= 0;
    bias                <= 0;
  end
  if(new_instr && (message_type ="A" || message_type ="F") && buy_sell_indicator = "B") begin
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
logic new_lowest;
logic calculated_index;
//Updates  bid books
always @(posedge clk) begin
  if(reset) begin
    min_price_bid <= 0;
    new_lowest <= 0;
    calculated_index <= 0;
  end
  else begin
    min_price_bid <= bid_levels[book_bid_origin_ptr];
    max_price_bid <= min_price_bid + 63 * TICK_SIZE;
    if(new_lowest) begin
      book_bid_origin_ptr <= index;
      new_lowest <= 0;
    end

  //stage 1
    if(new_instr && (message_type ="A" || message_type ="F") && buy_sell_indicator = "B") begin
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
        calculated_index <= 1;
      end
    end


//stage 2, update value at the index
  if(calculated_index) begin
    bid_levels[index_bid].price <= price;
    bid_levels[index_bid].quantity <= bid_levels[index_bid].quantity + quantity;
    bid_levels[index_bid].order_count <= bid_levels[index_bid].order_count + 1;
    calculated_index <= 0;
  end

  end
end


endmodule