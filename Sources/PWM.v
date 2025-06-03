/*To calculate the DUTY parameter for various duty cyles, follow the formula:
        DUTY=Duty Cycle * TOP(top value of counter)
        TOP=2^resolution-1
        after duty is calculated, applying ceiling function. 
        DUTY=512 for 50 percent
        DUTY=123 for 12 percent*/


`timescale 1ns / 1ps

module PWM #(
      parameter RESOLUTION=10,
      parameter DUTY=512
    )(
    input clk,rst,
    //output reg [RESOLUTION-1:0] counter,  //only used for debugging
    output reg PWM_out
    );
    
   reg [RESOLUTION-1:0] counter;
    
    always @(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                    counter<=0;
                    PWM_out<=0;
                end
             
             else
             //control logic for the PWM pulse
             PWM_out<=(counter<DUTY)?1'b1:1'b0;
              
             counter<=counter+1;                       
        end   
endmodule
