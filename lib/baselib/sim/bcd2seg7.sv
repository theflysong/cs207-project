`timescale 1ns/1ps

`ifndef __VCD_FILE__
`define __VCD_FILE__ "bcd2seg7.vcd"
`endif

module tb_bcd2seg7;
    localparam int DEFAULT_N = 4;
    localparam int WIDE_N = 8;

    logic [3:0] bcd_unit;
    wire [7:0] unit_anode, unit_cathode;
    logic [DEFAULT_N-1:0][3:0] bcd_default;
    wire [DEFAULT_N-1:0][7:0] default_anode, default_cathode;
    logic [WIDE_N-1:0][3:0] bcd_wide;
    wire [WIDE_N-1:0][7:0] wide_anode, wide_cathode;

    bcd2seg7_u unit_anode_dut (
        .bcd_in(bcd_unit), .seg7_out(unit_anode)
    );
    bcd2seg7_u #(.polarity(SEG7_CATHODE)) unit_cathode_dut (
        .bcd_in(bcd_unit), .seg7_out(unit_cathode)
    );

    bcd2seg7 default_anode_dut (
        .bcd_in(bcd_default), .seg7_out(default_anode)
    );
    bcd2seg7 #(.polarity(SEG7_CATHODE)) default_cathode_dut (
        .bcd_in(bcd_default), .seg7_out(default_cathode)
    );

    bcd2seg7 #(.N(WIDE_N), .polarity(SEG7_ANODE)) wide_anode_dut (
        .bcd_in(bcd_wide), .seg7_out(wide_anode)
    );
    bcd2seg7 #(.N(WIDE_N), .polarity(SEG7_CATHODE)) wide_cathode_dut (
        .bcd_in(bcd_wide), .seg7_out(wide_cathode)
    );

    function automatic logic [7:0] expected_cathode(input logic [3:0] value);
        case (value)
            4'd0: expected_cathode = 8'h3f;
            4'd1: expected_cathode = 8'h06;
            4'd2: expected_cathode = 8'h5b;
            4'd3: expected_cathode = 8'h4f;
            4'd4: expected_cathode = 8'h66;
            4'd5: expected_cathode = 8'h6d;
            4'd6: expected_cathode = 8'h7d;
            4'd7: expected_cathode = 8'h07;
            4'd8: expected_cathode = 8'h7f;
            4'd9: expected_cathode = 8'h6f;
            default: expected_cathode = 8'h00;
        endcase
    endfunction

    initial begin
        $dumpfile(`__VCD_FILE__);
        $dumpvars(0, tb_bcd2seg7);

        // 每一路遍历 0..15；各路输入不同，检查索引顺序与独立性。
        for (int value = 0; value < 16; value++) begin
            bcd_unit = 4'(value);
            for (int lane = 0; lane < DEFAULT_N; lane++)
                bcd_default[lane] = 4'(value + lane);
            for (int lane = 0; lane < WIDE_N; lane++)
                bcd_wide[lane] = 4'(value + 3 * lane);
            #1;

            if (unit_cathode !== expected_cathode(bcd_unit) ||
                unit_anode !== ~expected_cathode(bcd_unit))
                $fatal(1, "bcd2seg7_u: input=%0d anode=%h cathode=%h",
                       bcd_unit, unit_anode, unit_cathode);

            for (int lane = 0; lane < DEFAULT_N; lane++) begin
                if (default_cathode[lane] !== expected_cathode(bcd_default[lane]) ||
                    default_anode[lane] !== ~expected_cathode(bcd_default[lane]))
                    $fatal(1, "bcd2seg7 default: lane=%0d input=%0d anode=%h cathode=%h",
                           lane, bcd_default[lane], default_anode[lane], default_cathode[lane]);
            end
            for (int lane = 0; lane < WIDE_N; lane++) begin
                if (wide_cathode[lane] !== expected_cathode(bcd_wide[lane]) ||
                    wide_anode[lane] !== ~expected_cathode(bcd_wide[lane]))
                    $fatal(1, "bcd2seg7 N=%0d: lane=%0d input=%0d anode=%h cathode=%h",
                           WIDE_N, lane, bcd_wide[lane], wide_anode[lane], wide_cathode[lane]);
            end
        end

        $display("PASS: bcd2seg7_u and bcd2seg7 N=4/8, both polarities, inputs 0-15");
        $finish;
    end
endmodule
