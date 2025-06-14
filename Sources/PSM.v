/*This module which will skip user defined PWM cycles. 
It will act as basic PSM for open loop configuration*/

`timescale 1ns / 1ps

module PSM #(
        parameter RESOLUTION=8,
        parameter DUTY=128,
        parameter SKIP=5
    )(
        input clk,rst,
        output reg PSM_out
        //output debug_PWM  //only for debugging
      );
      
      localparam SKIP_WIDTH=$clog2(SKIP);
      reg pass_pulse;
      reg [SKIP_WIDTH:0] skip_counter;
      wire PWM;
      
      PWM #(.RESOLUTION(RESOLUTION),.DUTY(DUTY))
        (
            .clk(clk),
            .rst(rst),
            .PWM_out(PWM)
            );
      
      //this procedural block is responsible for finding the number of pulses to skip.      
      always @(posedge PWM or posedge rst)
        begin
            if(rst)
               begin
                  pass_pulse<=1;
                  skip_counter<=SKIP;
               end
            
            else
                begin
                    pass_pulse<=(skip_counter==SKIP);
                    skip_counter<=(skip_counter==0)?SKIP:(skip_counter-1);
                end
        end
      
      always @(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    PSM_out<=0;
                end
             
             else
                begin
                   PSM_out<=PWM & pass_pulse;
                end             
        end       
        //assign debug_PWM=PWM;     //only for debugging
endmodule