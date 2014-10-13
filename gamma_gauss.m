% gamma_gauss.m
% 
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function y = gamma_gauss(x,a,b,c,tau,n,A)

% compute the gamma function
y = filter_gamma(tau,n,A,x);
%y = a*exp(-((x-b)./c).^2);

