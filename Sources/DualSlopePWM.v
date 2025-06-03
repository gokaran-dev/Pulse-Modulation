/*To calculate the DUTY parameter for various duty cyles, follow the formula:
        DUTY=Duty Cycle * TOP(top value of counter)
        TOP=2^resolution-1
        after duty is calculated, applying ceiling function. 
        DUTY=512 for 50 percent
        DUTY=123 for 12 percent*/

`timescale 1ns / 1ps

module DualSlopePWM #(
    parameter RESOLUTION=10,
    parameter DUTY=123
  )(
    input clk,rst,
    //output reg [RESOLUTION-1:0] counter, //only for debugging
    //output reg direction,                //only for debugging
    output reg PWM_out
);

    localparam TOP=(1<<RESOLUTION)-1;   //this will give us the top count of a counter. 2^N-1

    reg [RESOLUTION-1:0] counter;
    reg next_direction,direction;

    always @(*) 
      begin
        next_direction=direction;

        if (counter==TOP)
            next_direction=0;
            
        else if (counter==0)
            next_direction=1;
            
    end

    always @(posedge clk or posedge rst) 
      begin
        if(rst) 
          begin
            counter<=0;
            direction<=1;
            PWM_out<=0;
          end 
        
        else 
          begin
            direction<=next_direction;
            
            //deciding whether to upcount or downcount based on the previous direction
            counter<=(next_direction)?(counter+1):(counter-1);
            //PWM Output
            PWM_out<=(counter<DUTY);
        end
    end
endmodule
