function [ dataM ] = getDataM( data, m )
%GETDATAM Summary of this function goes here
%   Detailed explanation goes here

dataM = data;
dataM(3,:) = data(3,:) - m;

end

