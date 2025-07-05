/*PSM with dynamic switching between PWM and PSM, also with dynamic threshold adjustment.
Dynamic Threshold adjustment tightens the hysteresis window, 
and adjusts it according to the system needs*/

`timescale 1ns / 1ps

module PSM_3 #(
    parameter RESOLUTION = 9,
    parameter DUTY = 256
)(
    input clk,
    input reset_in,
    input vauxp0,
    input vauxn0,
    output drdy_out,
    output reg load_volt_regulation,
    output reg APSM_out 
);

    wire [6:0] daddr_in = 7'h10;
    wire [15:0] do_out;
    wire [4:0] channel_out;
    wire eoc_out, alarm_out, eos_out, busy_out;
    wire PWM;

    // ADC instantiation
    xadc_wiz_0 ADC_inst (
        .di_in(16'd0),
        .daddr_in(daddr_in),
        .den_in(eoc_out),
        .dwe_in(1'b0),
        .drdy_out(drdy_out),
        .do_out(do_out),
        .dclk_in(clk),
        .reset_in(reset_in),
        .vp_in(1'd0),
        .vn_in(1'd0),
        .vauxp0(vauxp0),
        .vauxn0(vauxn0),
        .channel_out(channel_out),
        .eoc_out(eoc_out),
        .alarm_out(alarm_out),
        .eos_out(eos_out),
        .busy_out(busy_out)
    );

    // PWM generator
    PWM #(.RESOLUTION(RESOLUTION), .DUTY(DUTY)) pwm_inst (
        .clk(clk),
        .rst(reset_in),
        .PWM_out(PWM)
    );

  
    // Reference = 3722 (corresponding to 6V after divider)
    localparam [11:0] V_REF = 12'd3730;
    localparam [11:0] BASE_LOW  = 12'd3610;
    localparam [11:0] BASE_HIGH = 12'd3644;

    wire signed [12:0] error;
    assign error = $signed(V_REF) - $signed(do_out[15:4]);

    wire [11:0] low_threshold;
    wire [11:0] high_threshold;

    // Shift factors can be put to 3 and 4 for less aggressive tuning 
    assign low_threshold  = BASE_LOW  - (error >>> 2);  
    assign high_threshold = BASE_HIGH - (error >>> 3); 
    assign emergency_boost = (error>13'd128);
 

    always @(posedge clk) 
      begin
        if (reset_in) 
          begin
            load_volt_regulation <= 1'b0;
            APSM_out <= 1'b0;
          end
        
        else if(drdy_out) 
          begin
            if(do_out[15:4] < low_threshold) 
              begin
               load_volt_regulation <= 1;
              end
              
            else if (do_out[15:4] > high_threshold) 
              begin
                load_volt_regulation <= 0;
              end
              
              if(emergency_boost)
                APSM_out<=PWM;
              
              else
                APSM_out <= PWM & load_volt_regulation;
                 
        end
    end

    // Debug ILA
    ila_0 ILA_1 (
        .clk(clk),
        .probe0(do_out[15:4]),
        .probe1(daddr_in[6:0]),
        .probe2(low_threshold),
        .probe3(high_threshold)
    );

endmodule
