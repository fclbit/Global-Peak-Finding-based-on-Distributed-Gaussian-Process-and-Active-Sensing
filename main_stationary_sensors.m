% Title: Global Peak Finding based on Distributed Gaussian Process and Active Sensing
% Author: Weijie Qi, Yunru Qu
% Date  : 01-2023

clc;
close all;
clear all;

% The parameters here can be modified by the users

S = 10; % The number of stationary sensors is S*S��corresponds to traing points density
r = 1.0; % The range of communication with surrounding sensors
a = 100; % test points density
E = 100;
sigma = 0.0001;
M = 18; % iteration times
SHOW = 10; % show the result of the Sth sensor
gamma = 0.7;
v = 0.01;
l = 0.01;
interval = 1;

% Show the environment
InputSpace_test = {linspace(-4, 4, a); linspace(-4, 4, a)};
% ShowEnvironment3D(InputSpace);
ShowTopDownView(InputSpace_test);

% Load pre-computed LUT 
load mat/InputSpace_(-4,4,100)_E_463.mat
global Eig_LUT InputSpace_LUT;
Eig_LUT = Eigenfunctions;
InputSpace_LUT = InputSpace;

% Find the eigenfunctions and eigenvalues of Inputspace_test
[test_x, test_y] = meshgrid(InputSpace_test{1},InputSpace_test{2});
TestPoints = zeros(a*a, 2);
TestPoints(:, 1) = test_x(:)';
TestPoints(:, 2) = test_y(:)';
PHI = Find_Eigenfunctions_by_LUT(TestPoints,E);
LAMBDA = diag(Eigenvalues(1:E));

% kernel of test points
K = zeros(a*a);
[tmp_xx, tmp_yy] = meshgrid(linspace(-4, 4, a));
tmp_x = tmp_xx(:);
tmp_y = tmp_yy(:);
for i = 1:a*a
    for j = 1:a*a        
        distance = sqrt((tmp_x(i) - tmp_x(j))^2 + (tmp_y(i) - tmp_y(j))^2);
        K(i,j) = exp(-0.5*distance^2/v)*l+11;
    end
end

% Initialize the stationary sensors
InputSpace_train = {linspace(-2.5, 2.5, S);linspace(-2.5, 2.5, S)};
[train_x, train_y] = meshgrid(InputSpace_train{1},InputSpace_train{2});
StationarySensors = zeros(S*S, 2);
% train_x = train_x';train_y = train_y';
StationarySensors(:, 1) = train_x(:)';
StationarySensors(:, 2) = train_y(:)';
[Adj, tran] = BuildAdj(StationarySensors, r); % Adjacency matrix
y_s = f(train_x, train_y) + sigma*randn(size(train_x));
y_s = y_s(:);

if 1 % if you wannt to see the distributed result here  
%     G = Find_Eigenfunctions_by_LUT(InputSpace_train,E);
    G = Find_Eigenfunctions_by_LUT(StationarySensors,E);
    f_E_central = PHI * pinv(G'*G/S^2+sigma^2/S^2*pinv(LAMBDA)) * G'/S^2*y_s; 
    figure(3)
    pcolor(tmp_xx,tmp_yy,reshape(f_E_central,a,a));
    colorbar
    k = K - PHI * pinv(G'*G/S^2+sigma^2/S^2*pinv(LAMBDA)) * G'/S *G *LAMBDA*PHI'; 
    figure(4)
    pcolor(tmp_xx,tmp_yy,reshape(diag(k),a,a));
    colorbar
end

% Intialize alpha and beta
alpha = zeros(S*S,E*E); % (1,E*E) every sensor
beta = zeros(S*S,E); % (1,E) every sensor
for i = 1:S
    for j = 1:S
        n = (i-1)*S+j;
        phi = Find_Eigenfunctions_by_LUT([InputSpace_train{1}(i),InputSpace_train{2}(j)],E);
        tmp = phi' * phi;
        alpha(n,:) = tmp(:);
        beta(n,:) = phi' * y_s(n);
    end
end

% Start iteration
f_E = cell(S*S,1);
Pi_E = cell(S*S,1);
m = 1;
while m <= M
    for n = 1:S*S        
        if mod(m,interval) == 0
            if n == SHOW
                f_E{n} = PHI * pinv(reshape(alpha(n,:),E,E)+sigma^2/S^2*pinv(LAMBDA)) * beta(n,:)';
                Pi_E{n} = K - PHI * pinv(reshape(alpha(n,:),E,E)+sigma^2/S^2*pinv(LAMBDA)) * reshape(alpha(n,:),E,E)*LAMBDA*PHI';                
            end       
        end
    end
    % average consensus
    alpha = alpha - gamma*tran*alpha;
    beta = beta - gamma*tran*beta;
    % plot
    if mod(m,interval) == 0
        figure(m+10)        
        pcolor(tmp_xx,tmp_yy,reshape(f_E{SHOW},a,a));
        colorbar
        shading flat
        figure(m+100)
        pcolor(tmp_xx,tmp_yy,reshape(diag(Pi_E{SHOW}),a,a));                
        colorbar
        shading flat
    end
    m = m+1;
end