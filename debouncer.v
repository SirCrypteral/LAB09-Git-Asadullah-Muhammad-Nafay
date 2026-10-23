`timescale 1ns / 1ps

module debouncer(
    input  clk,
    input  pbin,
    output reg pbout
);
    initial pbout = 1'b0;

    reg        s0 = 1'b0, s1 = 1'b0;   // 2-flop synchronizer
    reg [19:0] cnt = 20'd0;            // 2^20 cycles = ~10.5 ms at 100 MHz

    always @(posedge clk) begin
        s0 <= pbin;
        s1 <= s0;
        if (s1 == pbout)
            cnt <= 20'd0;                  // input agrees with output: restart
        else begin
            cnt <= cnt + 1'b1;
            if (cnt == 20'hFFFFF)          // input stable long enough: accept it
                pbout <= s1;
        end
    end
endmodule