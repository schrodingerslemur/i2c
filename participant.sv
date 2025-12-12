module participant #(
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 8
) (
    input  logic clock, reset,

    // Shared I2C lines
    inout  tri sda, scl,

    // Participant interface
    input  logic  [ADDR_WIDTH-1:0]   own_addr,

    // Reading
    output logic  [DATA_WIDTH-1:0]   rx_data,
    output logic                     valid,

    // Writing
    input  logic [DATA_WIDTH-1:0]    tx_data,
    input  logic                     ready,

    // Status
    output logic                     busy,
    output logic                     ack_error
); 
    
endmodule: participant