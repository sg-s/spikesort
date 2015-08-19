% gamma_gauss.m
% sums a gamma and a gaussian function
% where is this used? candidate for removal...
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function y = gamma_gauss(x,a1,b1,c1,a2,b2,c2)

% compute the gamma function
y1 = a1*(x-c1).^b1;
y2 = a2*exp(-((x-b2)./c2).^2);
y = y1+y2;
