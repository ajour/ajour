Adds functions:

PixelGlow_Start(frame[, color[, N[, frequency[, length[, th[, xOffset[, yOffset[, border[ ,key]]]]]]]])

Starts glow over target frame with set parameters:

frame - target frame to set glowing;
color - {r,g,b,a}, color of lines and opacity, from 0 to 1. Defaul value is {0.95, 0.95, 0.32, 1};
N - number of lines. Defaul value is 8;
frequency - frequency, set to negative to inverse direction of rotation. Default value is 0.25;
length - length of lines. Default value depends on region size and number of lines;
th - thickness of lines. Default value is 2;
xOffset,yOffset - offset of glow relative to region border;
border - set to true to create border under lines;
key - key of glow, allows for multiple glows on one frame;
PixelGlow_Stop(frame[, key])

Stops glow with set key over target frame

 

AutoCastGlow_Start(frame[, color[, N[, frequency[, scale[, xOffset[, yOffset[, key]]]]]]])

Starts glow over target frame with set parameters:

frame - target frame to set glowing;
color - {r,g,b,a}, color of particles and opacity, from 0 to 1. Defaul value is {0.95, 0.95, 0.32, 1};
N - number of particle groups. Each group contains 4 particles. Defaul value is 4;
frequency - frequency, set to negative to inverse direction of rotation. Default value is 0.125;
scale - scale of particles;
xOffset,yOffset - offset of glow relative to region border;
key - key of glow, allows for multiple glows on one frame;
AutoCastGlow_Stop(frame[, key])

 Stops glow with set key over target frame

 

Blizzard glow is based heavily on https://www.wowace.com/projects/libbuttonglow-1-0

ButtonGlow_Start(frame[, color[, frequency]]])

 Starts glow over target frame with set parameters:

frame - target frame to set glowing;
color - {r,g,b,a}, color of particles and opacity, from 0 to 1. Defaul value is {0.95, 0.95, 0.32, 1};
frequency - frequency. Default value is 0.125;
ButtonGlow_Stop(frame)

Stops glow over target frame

 
