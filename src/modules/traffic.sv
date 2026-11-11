typedef enum logic [2:0] {
    TL_RED = 2'b00,
    TL_YLW = 2'b01,
    TL_GRN = 2'b10
} traffic_light_e;

module traffic_light (
    clk_if.sink cr,
    baselib::sig_t sig,
    output traffic_light_e light
);
    traffic_light_e cur_state, nxt_state;

    always_ff @(posedge cr.clk or negedge cr.rst_n) begin
        if (!cr.rst_n) begin
            cur_state <= TL_RED;
        end else begin
            cur_state <= nxt_state;
        end
    end

    always_comb begin
        case (cur_state)
            TL_RED: nxt_state = sig.pos ? TL_GRN : TL_RED;
            TL_GRN: nxt_state = sig.pos ? TL_YLW : TL_GRN;
            TL_YLW: nxt_state = sig.pos ? TL_RED : TL_YLW;
            default: nxt_state = TL_RED;
        endcase
    end

    assign light = cur_state;
endmodule

module traffic_light_2_seg7 #(
    parameter baselib::seg7_polarity_e polarity = baselib::SEG7_ANODE
)(
    input traffic_light_e light,
    output logic [7:0] seg7_out
);
    function automatic logic [7:0] encode(input traffic_light_e light);
        case (light)
            TL_RED: return 8'b0011_0001;  // 显示 "r"
            TL_GRN: return 8'b0011_1101;  // 显示 "g"
            TL_YLW: return 8'b0110_1110;  // 显示 "y"
            default: return 8'b0000_0000; // 全灭
        endcase
    endfunction

    always_comb begin
        seg7_out = encode(light);
        if (polarity == baselib::SEG7_ANODE)
            seg7_out = ~seg7_out;
    end
endmodule
