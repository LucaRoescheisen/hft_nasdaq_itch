package toeplitz_hash;

function automatic [9:0] hash1(input logic [63:0] ref_num);
  localparam logic [79:0] KEY_A = 80'h6C62272E07BB01428D7F;
  for(int i = 0; i < 10; i++) begin
    hash1[i] = ^(ref_num & KEY_A[63 + i -: 64]);
  end
endfunction

function automatic [9:0] hash2(input logic [63:0] ref_num);
  localparam logic [79:0] KEY_B = 80'h9E3779B97F4A7C15FD13;
  for(int i = 0; i < 10; i++) begin
    hash2[i] = ^(ref_num & KEY_B[63 + i -: 64]);
  end
endfunction

endpackage
