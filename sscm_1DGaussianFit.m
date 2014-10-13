% sscm_1DGaussianFit.m
% this is a cluster plugin for spikesort.m
% this clustering method splits a 1-dimensional dataset into two assuming that they result from two gaussians
% created by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [A,B] = sscm_1DGaussianFit(R,loc)

[y,x] = hist(R,floor(length(R)/30));
if length(x) < 6
	[y,x] = hist(R,floor(length(R)/(floor(length(R)/6))));
end
y = y(:); x = x(:);
temp = fit(x(:),y(:),'gauss2'); % split into two groups
g1=temp.a1.*exp(-((x-temp.b1)./temp.c1).^2);
g2=temp.a2.*exp(-((x-temp.b2)./temp.c2).^2);
if temp.b1 > temp.b2
    cutoff=find((g2-g1)>0,1,'last');
    cutoff = x(cutoff);
else
    cutoff=find((g1-g2)>0,1,'last');
    cutoff = x(cutoff);

end


if (cutoff-temp.b1)*(cutoff-temp.b2) > 0
	% bad fit to 2 gaussians, as the cutoff is useless and not separating the points well
	% we're going to fall back to a horribly ad-hoc solution

	% first fit a power law to the data
	[~,my] = max(y);
	f=fit(x(1:my),y(1:my),'power1');

	% find where it deviates most
	[~,p]=max(y(:)-f(x));

	% find the minimum after this
	[~,cutoff]=min(y(p:my));
	cutoff = x(cutoff+p);

	B = loc(R<cutoff);
	A = loc(R>=cutoff);

	% fall back to k-means
	% idx=kmeans(R(:),2);
	% if mean(R(idx==1)) > mean(R(idx==2))
	% 	A=loc(idx==1); B = loc(idx==2);
	% else
	% 	B=loc(idx==1); A = loc(idx==2);
	% end

	% keyboard
	% options = fitoptions('gauss2');
	% options.Lower = [0 min(x) 0 0 .5 0];
	% options.Upper = [Inf .5 Inf Inf Inf Inf];
	% temp = fit(x(:),y(:),'gauss2',options);
	% g1=temp.a1.*exp(-((x-temp.b1)./temp.c1).^2);
	% g2=temp.a2.*exp(-((x-temp.b2)./temp.c2).^2);
	% if temp.b1 > temp.b2
	%     cutoff=find((g2-g1)>0,1,'last');
	%     cutoff = x(cutoff);
	% else
	%     cutoff=find((g1-g2)>0,1,'last');
	%     cutoff = x(cutoff);

	% end

else
	% mark as A or B
	if isempty(cutoff)
		% something wrong, fall back to labelling everything as A
		A = loc;
		B = [];
	else
		B = loc(R<cutoff);
		A = loc(R>=cutoff);
	end
end