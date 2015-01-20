function [  ] = plotRout( x, y, z )
%PLOTROUT Summary of this function goes here
%   Detailed explanation goes here

% figure;
plot3(x,y,z,'b.-');
xlabel('x');
ylabel('y');
zlabel('z');
grid on
axis([-2 2 -2 2 -1 1 0 1]);

end

