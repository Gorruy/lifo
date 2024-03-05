interface lifo_interface #(
  parameter DWIDTH       = 16,
  parameter AWIDTH       = 8,
  parameter ALMOST_EMPTY = 2,
  parameter ALMOST_FULL  = 2
) (
  input bit clk
);
  
  logic                srst;

  logic [DWIDTH - 1:0] data;
  logic                wrreq;
  logic                rdreq;

  logic [DWIDTH - 1:0] q;
  logic                empty;
  logic                full;
  logic [AWIDTH:0]     usedw;
  logic                almost_full;
  logic                almost_empty;

endinterface //lifo_intfc