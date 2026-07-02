
function automatic [15:0] hash1(input logic [63:0] ref_num);
  localparam logic [78:0] KEY_A = 79'h6C62272E07BB01428D7F;
  for(int i = 0; i < 16; i++) begin
    hash1[i] = ^(ref_num & KEY_A[63 + i -: 64]);
  end
endfunction

function automatic [15:0] hash2(input logic [63:0] ref_num);
  localparam logic [78:0] KEY_B = 79'h9E3779B97F4A7C15FD13;
  for(int i = 0; i < 16; i++) begin
    hash2[i] = ^(ref_num & KEY_B[63 + i -: 64]);
  end
endfunction

