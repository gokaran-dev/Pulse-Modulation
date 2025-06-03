`timescale 1ns / 1ps

module DualSlopePWM_tb();
    
    parameter RESOLUTION=10;
    
    reg clk,rst;
    wire PWM_out;
   //wire [RESOLUTION-1:0]counter;
   //wire direction;
    
    DualSlopePWM uut(
            .clk(clk),
            .rst(rst),
            //.counter(counter),
            //.direction(direction),
            .PWM_out(PWM_out)
        );
        
    initial
        begin
            clk=0;
            rst=0;
            end
            
     always #5 clk=~clk;
     
     initial
        begin
            #100
            #10 rst=1;
            #10 rst=0;
            
            #500000 $finish;
        end
endmodule
