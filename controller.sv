module controller #(
    parameter ADDR_WIDTH = 7,
    parameter DATA_WIDTH = 8
) (
    input  logic                     clock,
    input  logic                     reset,
    inout  logic                     sda,
    inout  logic                     scl,
    input  logic [ADDR_WIDTH-1:0]    slave_addr,
    input  logic [DATA_WIDTH-1:0]    tx_data,
    input  logic                     ready,
    output logic  [DATA_WIDTH-1:0]   rx_data,
    output logic                     valid,
    output logic                     busy,
    output logic                     ack_error
);

endmodule: controller

