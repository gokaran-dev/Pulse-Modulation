/*This PSM module will take the load voltage into considration.
if voltage falls below a particular value, PWM will be enabled,
otherwise disabled. Should dynamically adjust the duty cycle and
more concious switching should save energy*/


`timescale 1ns / 1ps

module PSM_2 #(
        parameter RESOLUTION=8,
        parameter DUTY=128
    )(
      input clk, input reset_in,
      input vauxp0,vauxn0,
      //output [15:0] do_out,
      output drdy_out,
      output reg voltage_low,
      output reg test1,test2,
      output reg PSM_out
    );
    
 
   //wire [15:0] di_in;
   wire [6:0] daddr_in=7'h10;
   wire den_in;
   wire dwe_in;
   //wire drdy_out;
   wire [15:0] do_out;
   //wire vauxp0;
   //wire vauxn0;
   wire [4:0] channel_out;
   wire eoc_out;
   wire alarm_out;
   wire eos_out;
   wire busy_out;
   
   wire PWM;
   //reg voltage_low;
    
   xadc_wiz_0 ADC_inst(
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
        
    PWM #(.RESOLUTION(RESOLUTION),.DUTY(DUTY))
        (
       .clk(clk),
       .rst(reset_in),
       .PWM_out(PWM)
        );
    
    always @(posedge clk)
        begin
            if(reset_in)
                begin
                    voltage_low<=1'b0;
                    PSM_out<=0;
                end
            
          
            else if(drdy_out)
                   begin
                    if(do_out[15:4]<12'he1a) 
                        begin
                            voltage_low<=1;
                            test1<=1;
                            test2<=0;
                        end
                        
                     else if(do_out[15:4]>12'he3c)
                        begin
                            voltage_low<=0;
                            test2<=1;
                            test1<=0;
                        end
                        
                        PSM_out<= PWM & voltage_low;
                   end
        end
        
            ila_0 ILA_1(
	           .clk(clk), // input wire clk
               .probe0(do_out[15:4]),
               .probe1(daddr_in[6:0]) // input wire [15:0] probe0
            );
        
    //assign PSM_out=PWM & voltage_low;   
    //assign debug_voltage_low=voltage_low;
    //assign test_1=(do_out<16'h7333);
    //assign test_2=(do_out>16'he168);
    
endmodule
