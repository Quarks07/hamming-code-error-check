`timescale 1ns/1ps

module tb_hamming74;
    reg [3:0] data_in;
    reg [6:0] error_mask;
    wire [6:0] encoded, received, corrected;
    wire [2:0] syndrome;
    wire error_detected;
    wire [3:0] data_out;
    integer message, position, passes;

    hamming74 dut (
        .data_in(data_in), .error_mask(error_mask),
        .encoded(encoded), .received(received), .syndrome(syndrome),
        .error_detected(error_detected), .corrected(corrected),
        .data_out(data_out)
    );

    // Known codewords give the encoder a separate reference to check.
    function [6:0] expected_code;
        input [3:0] data;
        begin
            case (data)
                4'h0: expected_code = 7'b0000000;
                4'h1: expected_code = 7'b1001011;
                4'h2: expected_code = 7'b0101010;
                4'h3: expected_code = 7'b1100001;
                4'h4: expected_code = 7'b0011001;
                4'h5: expected_code = 7'b1010010;
                4'h6: expected_code = 7'b0110011;
                4'h7: expected_code = 7'b1111000;
                4'h8: expected_code = 7'b0000111;
                4'h9: expected_code = 7'b1001100;
                4'hA: expected_code = 7'b0101101;
                4'hB: expected_code = 7'b1100110;
                4'hC: expected_code = 7'b0011110;
                4'hD: expected_code = 7'b1010101;
                4'hE: expected_code = 7'b0110100;
                4'hF: expected_code = 7'b1111111;
            endcase
        end
    endfunction

    task check_result;
        input integer expected_position;
        begin
            if (encoded !== expected_code(data_in) ||
                received !== (expected_code(data_in) ^ error_mask) ||
                syndrome !== expected_position[2:0] ||
                error_detected !== (expected_position != 0) ||
                corrected !== expected_code(data_in) || data_out !== data_in) begin
                $display("FAIL: data=%b position=%0d out=%b syndrome=%b",
                         data_in, expected_position, data_out, syndrome);
                $fatal(1, "Unexpected result");
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_hamming74);
        passes = 0;
        data_in = 4'b1011;
        error_mask = 7'b0000000;
        $display("Hamming (7,4) - even parity");
        $display("Demo: data=1011, encoded=1100110");
        $display("pos  mask     received  syndrome  out");
        for (position = 0; position <= 7; position = position + 1) begin
            if (position == 0)
                error_mask = 0;
            else
                error_mask = 7'b0000001 << (position - 1);
            #10;
            check_result(position);
            $display(" %0d   %b  %b   %b       %b",
                     position, error_mask, received, syndrome, data_out);
        end

        // Remove the fault and check recovery.
        error_mask = 0;
        #10;
        check_result(0);

        // Two flipped bits show the limit of this code.
        error_mask = 7'b0000101;
        #10;
        if (received !== 7'b1100011 || syndrome !== 3'd2 ||
            corrected !== 7'b1100001 || data_out !== 4'b0011)
            $fatal(1, "Unexpected double-bit example");
        $display("Two-bit example: mask=%b, out=%b (incorrect, as expected)",
                 error_mask, data_out);

        // Test every message with no error and with each single-bit error.
        for (message = 0; message < 16; message = message + 1) begin
            data_in = message;
            for (position = 0; position <= 7; position = position + 1) begin
                if (position == 0)
                    error_mask = 0;
                else
                    error_mask = 7'b0000001 << (position - 1);
                #10;
                check_result(position);
                passes = passes + 1;
            end
        end
        $display("PASS: %0d checks (16 clean + 112 single-bit errors)", passes);
        $display("PASS: double-bit limitation example checked");
        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
