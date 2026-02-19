module fsm(
  input reset,
  input [31:0] payload_len,
  output [2:0] state_out
);

  parameter int ETH_LEN = 14;
  parameter int IP_LEN  = 24;
  parameter int UDP_LEN = 8;

typedef enum logic [2:0] { IDLE,
                           ETH,
                           IP,
                           UDP,
                           PAYLOAD
 } state_t;
state_t state, next_state;

always_ff @(posedge clk) begin
  if(reset) state <= IDLE;
  else : state <= next_state;
end

always_comb begin
  next_state = state;
  case(state)
    IDLE:    next_state = ETH;
    ETH:     if(byte_counter == (ETH_LEN - 1)          next_state = IP;
    IP:      if(byte_counter == (ETH_LEN + IP_LEN - 1)) next_state = UDP;
    UDP:     if(byte_counter == (ETH_LEN + IP_LEN + UDP_LEN - 1)) next_state = UDP;
    PAYLOAD: if(byte_counter == (ETH_LEN + IP_LEN + UDP_LEN + payload_len - 1)) next_state = IDLE;
  endcase
end

  assign state_out = state;

endmodule