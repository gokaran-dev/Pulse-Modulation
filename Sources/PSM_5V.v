`timescale 1ns / 1ps
module PSM_5V #(
    parameter RESOLUTION = 9,
    parameter DUTY = 225,
    parameter V_REF = 12'd3150,
    parameter BASE_LOW = 12'd3100,
    parameter BASE_HIGH = 12'd3200,
    parameter LOAD_FACTOR = 12'd60
)(
    input clk,
    input reset_in,
    input [11:0] volt_in,
    input [11:0] volt_other,
    input drdy_in,
    input load_sharing_active,
    output reg APSM_request,
    output drdy_out,
    output signed [12:0] error_5v,
    output [11:0] volt_out,
    output emergency_condition
);

    assign volt_out = volt_in;
    assign drdy_out = drdy_in;

    assign error_5v = $signed({1'b0, V_REF}) - $signed({1'b0, volt_in});

    // ????????????????????????????????????????
    // Dynamic emergency threshold selection
    wire [12:0] EMERGENCY_dynamic;
    assign EMERGENCY_dynamic = (load_sharing_active && error_5v > 0) ? 13'd300 : 13'd600;

    assign emergency_condition = (error_5v > $signed(EMERGENCY_dynamic));
    // ????????????????????????????????????????

    wire over_voltage_condition = (error_5v < -$signed(13'd180));
    wire max_overshoot = (volt_in > BASE_HIGH + 12'd5);
    wire clamp_output = over_voltage_condition || max_overshoot;

    reg [3:0] clamp_timer;
    wire clamp_hold = (clamp_timer > 0);
    wire emergency_allowed = (!clamp_output && !clamp_hold) ? emergency_condition : 1'b0;

    wire PWM;
    PWM #(.RESOLUTION(RESOLUTION), .DUTY(DUTY)) pwm_inst (
        .clk(clk),
        .rst(reset_in || clamp_output),
        .PWM_out(PWM)
    );

    wire [11:0] low_threshold  = BASE_LOW - (error_5v >>> 1);
    wire [11:0] high_threshold = BASE_HIGH - (error_5v >>> 2);

    reg load_volt_regulation;

    always @(posedge clk) begin
        if (reset_in) begin
            load_volt_regulation <= 1'b0;
            APSM_request <= 1'b0;
            clamp_timer <= 0;
        end else if (drdy_in) begin
            if (clamp_output)
                clamp_timer <= 4'd7;
            else if (clamp_timer > 0)
                clamp_timer <= clamp_timer - 1;

            if (volt_in < low_threshold && !clamp_output)
                load_volt_regulation <= 1;
            else if (volt_in > high_threshold)
                load_volt_regulation <= 0;

            if (clamp_output)
                load_volt_regulation <= 0;

            APSM_request <= !(clamp_output || clamp_hold) && ((PWM & load_volt_regulation) || emergency_allowed);
        end
    end

    // Debug ILA
    ila_4 your_instance_name (
        .clk(clk),
        .probe0(V_REF),
        .probe1(volt_in),
        .probe2(drdy_in),
        .probe3(error_5v)
    );

endmodule
