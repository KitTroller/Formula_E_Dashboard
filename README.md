#Formula Student/ Formula E vehicle Dashboard
##This is my greatest and proudest project yet

This project is using industry standard C++ using Qt backend and QML frontend, decoupling graphics from logic. By running this code you will see a
wonderfull display(meant for an 800 by 480 screen). This code is the final puzzle piece in a formula data flow towards the vehicle dashboard.
It is meant to run in a raspberry pi (fast sd cards recommended for sub 10 second boot time on a pi) and recieve UART. The code is well commented
so one can easily edit/adjust the backend to suit ones needs. The current cpp file expects 88 uart variables.This ofcourse can be adjusted to recieve
and decode raw can data or data from an mqtt broker for a remote implementation. I recommend to keep the variables outside a struct because due to the 
Qt signals and slots "technology used" to increase efficiency only the specific variable that changes at a given time will fire off a signal to change
the frontend. Using a struct would disable this extra efficiency feature.

You can test this locally on your computer by either writting a short script or using the following commands in the terminal
socat -d -d pty,raw,echo=0,link=/tmp/ttyV0 pty,raw,echo=0,link=/tmp/ttyV1


echo "0,0.0,0.0,0,0.0,0.0,0.0,0.0,54.0,1,1,1,1,1,1,5,300.0,0.0,0.0,0.0,45.0,105.0,2.70,3.10,0,0,0,0,0,0,0,0,0,0,0,0,0.5,0.5,0.5,0.5,20.0,20.0,20.0,20.0,80.0,80.0,80.0,80.0,95.0,95.0,90.0,90.0,3.00,3.00,3.00,2.70,3.00,3.00,3.00,3.00,3.00,3.00,3.00,3.00,3.10,3.10,3.10,3.10,3.10,3.10,3.10,3.10,3.10,3.10,3.10,3.10,50.0,50.0,50.0,50.0,50.0,50.0,105.0,50.0,50.0,50.0,50.0,50.0" > /tmp/ttyV1

echo "120,45.2,-0.124,4,1.6,0.9,0.95,0.0,54.2,1,1,1,0,0,0,98,395.4,120.5,45.2,60.0,22.1,28.5,4.01,4.12,190,190,200,200,180,180,195,195,12500,12500,12800,12800,1.2,1.2,1.3,1.3,45.5,45.5,50.2,50.2,65.0,65.0,70.5,70.5,58.0,58.0,62.0,62.0,3.90,3.91,3.92,3.90,3.91,3.92,3.90,3.91,3.92,3.90,3.91,3.92,4.10,4.11,4.12,4.10,4.11,4.12,4.10,4.11,4.12,4.10,4.11,4.12,45.0,45.1,45.2,45.0,45.1,45.2,45.0,45.1,45.2,45.0,45.1,45.2" > /tmp/ttyV1

echo "45,46.1,0.2,5,-1.9,0.1,0.0,0.95,58.0,1,0,0,0,1,0,45,370.0,-40.0,-14.8,60.0,40.0,45.0,3.70,3.80,-15,-15,-20,-20,-15,-15,-20,-20,4000,4000,4100,4100,1.3,1.3,1.3,1.3,65.0,65.0,66.0,66.0,75.0,75.0,76.0,76.0,70.0,70.0,75.0,75.0,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.70,3.80,3.80,3.80,3.80,3.80,3.80,3.80,3.80,3.80,3.80,3.80,3.80,42.0,42.0,42.0,42.0,42.0,45.0,42.0,42.0,42.0,42.0,42.0,42.0" > /tmp/ttyV1  

