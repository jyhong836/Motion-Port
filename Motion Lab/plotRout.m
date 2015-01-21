function [ ] = plotRout( x, y, z )
%PLOTROUT Summary of this function goes here
%   Detailed explanation goes here

% figure;
h = plot3(x,y,z,'b.-');
xlabel('x');
ylabel('y');
zlabel('z');
% h.color = [0    0.4470    0.7410];
axis([-2 2 -2 2 -1 1 0 1]);
grid on

end

