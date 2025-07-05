//changes made:
/* 3:11AM 2:07:2025
1. switched from weighted errors comparison to just error.
2. using weighted errors to decide which state to serve next when both rails are active
3. made sure we do not need leave a SERVE state till emergency is met
4. arbitration when both requests are zero
5. removed priority boost concept
*/

`timescale 1ns / 1ps
module SIDO_controller(
    input clk,
    input reset,
    input request_5V,
    input request_3V3,
    input signed [12:0] error_3v3,
    input signed [12:0] error_5v,
    input emergency_5v,
    input emergency_3v3,
    output reg Q_main,
    output reg Q_5V_enable,
    output reg Q_3V3_enable,
    output wire load_sharing_active
);
    parameter IDLE      = 3'b000,
              DEADTIME  = 3'b001,
              SERVE_3V3 = 3'b010,
              SERVE_5V  = 3'b011,
              EMERGENCY = 3'b100;

    reg [2:0] state, next_state;
    reg [4:0] deadtime_counter;
    reg [7:0] service_counter;

    reg current_comparison_result;

    //to check for load conditions
    assign load_sharing_active = request_3V3 && request_5V;
    //wire load_imbalance = (error_3v3 > 150) || (error_5v > 150);

    //
    always @(posedge clk or posedge reset) 
      begin
        if (reset)
          begin
            state <= IDLE;
            deadtime_counter <= 0;
            service_counter <= 0;
            //load_sharing_active <= 0;
            current_comparison_result <= 0;
          end 
        
        else 
          begin
            state <= next_state;
            //load_sharing <= load_sharing active;

            case(state)
                IDLE: 
                  begin
                    deadtime_counter <= 0;
                    service_counter <= 0;
                  end

                DEADTIME: 
                  begin
                    service_counter <= 0;
                    if(deadtime_counter < 5'd8)
                        deadtime_counter <= deadtime_counter + 1;
                    else
                        deadtime_counter <= 0;

                    if (deadtime_counter == 5'd6 && request_3V3 && request_5V)
                      begin
                        current_comparison_result <= (error_3v3 >= error_5v);
                      end
                  end

                SERVE_3V3: 
                  begin
                    deadtime_counter <= 0;
                    if(service_counter < 255)
                        service_counter <= service_counter + 1;
                  end

                SERVE_5V: 
                  begin
                    deadtime_counter <= 0;
                    if(service_counter < 255)
                        service_counter <= service_counter + 1;
                  end

                EMERGENCY: 
                  begin
                    deadtime_counter <= 0;
                    service_counter <= 0;
                  end
              endcase
          end
      end


      //next state logic 
      always @(*) begin
          case(state)
            
            IDLE: 
              begin
                if (emergency_5v || emergency_3v3)
                    next_state = EMERGENCY;
                    
                else if (request_3V3 || request_5V)
                    next_state = DEADTIME;
                    
                else
                    next_state = IDLE;
            end

            DEADTIME: 
              begin
                if (emergency_5v || emergency_3v3)
                    next_state = EMERGENCY;
                    
                else if (deadtime_counter >= 5'd8) 
                  begin
                    if (request_3V3 && request_5V)
                        next_state = current_comparison_result ? SERVE_3V3 : SERVE_5V;
                        
                    else if (request_3V3)
                        next_state = SERVE_3V3;
                        
                    else if (request_5V)
                        next_state = SERVE_5V;
                        
                    else
                       next_state = IDLE;                      
                end 
                
                else
                    next_state = DEADTIME;
            end

            SERVE_3V3: 
              begin
                if (emergency_5v && emergency_3v3)
                    next_state = EMERGENCY;
                    
                else if (emergency_3v3)
                    next_state = SERVE_3V3;
                
                else if (emergency_5v)
                    next_state = EMERGENCY;
                    
                else if (!request_5V && !request_3V3)
                    next_state = IDLE; 
                    
                else if (!request_3V3)
                    next_state = IDLE;
                    
                else if (service_counter > 120)
                    next_state = DEADTIME;
                
                //this can also be error based. This is for the condition when there is a heavier load on 5V rail    
                else if (request_5V && service_counter > 25)
                    next_state = DEADTIME;
                    
                else
                    next_state = SERVE_3V3;
            end

            SERVE_5V: 
              begin
                if (emergency_5v && emergency_3v3)
                    next_state = EMERGENCY;
                    
                else if (emergency_5v)
                    next_state = SERVE_5V;
                    
                else if (emergency_3v3)
                    next_state = EMERGENCY;
                 
                else if (!request_5V && !request_3V3)
                    next_state = IDLE;    
                    
                else if (!request_5V)
                    next_state = IDLE;
                    
                else if (service_counter > 80)
                    next_state = DEADTIME;
                
                //in place to allow fair energy transfer during high load situations    
                else if (request_3V3 && service_counter > 25)
                    next_state = DEADTIME;
                    
                else
                    next_state = SERVE_5V;
              end

            EMERGENCY: 
              begin
                if (emergency_5v && emergency_3v3) 
                  begin
                    next_state = (error_5v >= error_3v3) ? SERVE_5V : SERVE_3V3;
                  end 
                
                else if (emergency_5v)
                    next_state = SERVE_5V;
                    
                else if (emergency_3v3)
                    next_state = SERVE_3V3;
                    
                else if (request_3V3 || request_5V)
                    next_state = DEADTIME;
                    
                else
                    next_state = IDLE;
                end

                default: next_state = IDLE;
          endcase
      end
      
      //switching logic
      always @(*) 
      begin
        Q_main = 0;
        Q_5V_enable = 0;
        Q_3V3_enable = 0;

        case(state)
            SERVE_3V3: 
              begin
                Q_main = 1;
                Q_3V3_enable = 1;
              end

            SERVE_5V: 
              begin
                Q_main = 1;
                Q_5V_enable = 1;
              end

            EMERGENCY: 
              begin
                Q_main = 1;
                
                if (emergency_5v && !emergency_3v3)
                    Q_5V_enable = 1;
                    
                else if (emergency_3v3 && !emergency_5v)
                    Q_3V3_enable = 1;
                    
                else if (emergency_5v && emergency_3v3) 
                  begin
                    if (error_5v >= error_3v3)
                        Q_5V_enable = 1;
                    else
                        Q_3V3_enable = 1;
                  end
              end
          endcase
      end
      
endmodule
