
function exportDataForTensorFlow(s)

snippet_size = 300;

A = s.A;
B = s.B;
N = s.N;

A(A>length(s.time)-snippet_size-1) = [];
A(A<snippet_size+1) = [];

B(B>length(s.time)-snippet_size-1) = [];
B(B<snippet_size+1) = [];

N(N>length(s.time)-snippet_size+1) = [];
N(N<snippet_size+1) = [];

% create variables for spikes and 1-hot encoded data 

X = zeros(snippet_size*2+1,length(A) + length(B) + length(N));
c = 1;
Y = zeros(3,size(X,2));

for i = 1:length(A)
	X(:,c) = s.filtered_voltage(A(i)-snippet_size:A(i)+snippet_size);
	Y(1,c) = 1;
	c = c + 1;
end

for i = 1:length(B)
	X(:,c) = s.filtered_voltage(B(i)-snippet_size:B(i)+snippet_size);
	Y(2,c) = 1;
	c = c + 1;
end

for i = 1:length(N)
	X(:,c) = s.filtered_voltage(N(i)-snippet_size:N(i)+snippet_size);
	Y(3,c) = 1;
	c = c + 1;
end


savefast('X.mat','X')
savefast('Y.mat','Y')
