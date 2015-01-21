function [ x, v ] = getXV( ar, st, t )
%GETXV Summary of this function goes here
%   ar - raw accellerate
%   st - start data

% dt = 1/60.0;
% len = length(ar);
[r,len] = size(ar);
v = zeros(r, len+1);
x = zeros(r, len+1);

x(:,1) = st(:,1);
v(:,1) = st(:,2);

k = 10;
t(end+1) = 2*t(end) - t(end-1);
for idx = 1:len
    at = ar(:,idx) - k*v(:,idx);
%     disp(1/(t(idx+1) - t(idx)));
    v(:,idx+1) = v(:,idx) + at * (t(idx+1) - t(idx));
    x(:,idx+1) = x(:,idx) + (v(:,idx+1) + v(:,idx))/2 *(t(idx+1) - t(idx));
end

end

