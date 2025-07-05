`timescale 1ns / 1ps
module PSM_3V3 #(
    parameter RESOLUTION = 8,
    parameter DUTY = 71,                // previously it was 73
    parameter V_REF = 12'd3430,
    parameter BASE_LOW = 12'd3410,
    parameter BASE_HIGH = 12'd3470,
    parameter LOAD_FACTOR = 12'd50,
    parameter EMERGENCY = 13'd400
)(
    input clk,
    input reset_in,
    input drdy_in,
    input [11:0] volt_in,
    input [11:0] volt_other,
    input load_sharing_active,
    output reg APSM_request,
    output drdy_out,
    output signed [12:0] error_3v3,
    output [11:0] volt_out,
    output emergency_condition
);

    // Output assignments
    assign volt_out = volt_in;
    assign drdy_out = drdy_in;

    // Error and clamp detection
    assign error_3v3 = $signed({1'b0, V_REF}) - $signed({1'b0, volt_in});
    assign emergency_condition = (error_3v3 > $signed(EMERGENCY));
    wire over_voltage_condition = (error_3v3 < -$signed(13'd180));
    wire max_overshoot = (volt_in > BASE_HIGH + 12'd10);
    wire clamp_output = over_voltage_condition || max_overshoot;

    // Clamp hold timer
    reg [3:0] clamp_timer;
    wire clamp_hold = (clamp_timer > 0);

    // PWM logic
    wire PWM;
    PWM #(.RESOLUTION(RESOLUTION), .DUTY(DUTY)) pwm_inst (
        .clk(clk),
        .rst(reset_in || clamp_output),
        .PWM_out(PWM)
    );

    // Adaptive thresholds
    wire [11:0] low_threshold  = BASE_LOW - (error_3v3 >>> 1);
    wire [11:0] high_threshold = BASE_HIGH - (error_3v3 >>> 2);

    // Load regulation flag
    reg load_volt_regulation;

    always @(posedge clk) begin
        if (reset_in) begin
            load_volt_regulation <= 1'b0;
            APSM_request <= 1'b0;
            clamp_timer <= 0;
        end
        else if (drdy_in) begin
            // Clamp hold timer
            if (clamp_output)
                clamp_timer <= 4'd10;
            else if (clamp_timer > 0)
                clamp_timer <= clamp_timer - 1;

            // Regulation logic
            if (volt_in < low_threshold && !clamp_output)
                load_volt_regulation <= 1;
            else if (volt_in > high_threshold)
                load_volt_regulation <= 0;

            if (clamp_output)
                load_volt_regulation <= 0;

            // APSM request logic
            APSM_request <= !(clamp_output || clamp_hold) && ((PWM & load_volt_regulation) || emergency_condition);
        end
    end

    // ILA probe
    ila_3 ILA_5 (
        .clk(clk),
        .probe0(volt_in),
        .probe1(volt_out),
        .probe2(drdy_in)
    );

endmodule
