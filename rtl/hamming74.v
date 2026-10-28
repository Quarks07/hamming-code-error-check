// Even-parity Hamming (7,4).
// Positions 1 to 7 use bits 0 to 6 respectively.
// Data bits [3:0] go into positions 3, 5, 6 and 7.
module hamming74 (
    input  wire [3:0] data_in,
    input  wire [6:0] error_mask,
    output wire [6:0] encoded,
    output wire [6:0] received,
    output wire [2:0] syndrome,
    output wire       error_detected,
    output reg  [6:0] corrected,
    output wire [3:0] data_out
);
    wire p1, p2, p4;

    assign p1 = data_in[3] ^ data_in[2] ^ data_in[0];
    assign p2 = data_in[3] ^ data_in[1] ^ data_in[0];
    assign p4 = data_in[2] ^ data_in[1] ^ data_in[0];

    assign encoded = {data_in[0], data_in[1], data_in[2], p4,
                      data_in[3], p2, p1};

    // Set a mask bit to 1 to flip that bit during simulation.
    assign received = encoded ^ error_mask;

    assign syndrome[0] = received[0] ^ received[2] ^ received[4] ^ received[6];
    assign syndrome[1] = received[1] ^ received[2] ^ received[5] ^ received[6];
    assign syndrome[2] = received[3] ^ received[4] ^ received[5] ^ received[6];
    assign error_detected = (syndrome != 3'b000);

    // The syndrome gives the error position when only one bit is wrong.
    always @(*) begin
        corrected = received;
        case (syndrome)
            3'd1: corrected[0] = ~received[0];
            3'd2: corrected[1] = ~received[1];
            3'd3: corrected[2] = ~received[2];
            3'd4: corrected[3] = ~received[3];
            3'd5: corrected[4] = ~received[4];
            3'd6: corrected[5] = ~received[5];
            3'd7: corrected[6] = ~received[6];
            default: corrected = received;
        endcase
    end

    assign data_out = {corrected[2], corrected[4], corrected[5], corrected[6]};
endmodule
