%% Sparse generalized linear model (GLM)
% A demonstration of sparse GLM regression using SparseReg 
% toolbox. Sparsity is in the general sense: variable selection, 
% fused sparse regression (total variation regularization), polynomial trend 
% filtering, and others. Various penalties are implemented:
% elestic net (enet), power family (bridge regression), log penalty, SCAD, 
% and MCP.

%% Sparse logistic regression (n>p)
% Simulate a sample data set (n=500, p=50)
clear;
n = 500;
p = 50;

X = randn(n,p);             % generate a random design matrix
X = bsxfun(@rdivide, X, sqrt(sum(X.^2,1))); % normalize predictors
X = [ones(size(X,1),1) X];
b = zeros(p+1,1);           % true signalfirst ten predictors are 5
b(2:6) = 5;                 % first 5 predictors are 5
b(7:11) = -5;               % next 5 predictors are -5
inner = X*b;                % linear parts
prob = 1./(1+exp(-inner));
y = double(rand(n,1)<prob);

%%
% Sparse logistic regression at a fixed tuning parameter value
c = [];                     % constant vector is 0 by default
model = 'logistic';         % set model to logistic
penidx = [false; true(size(X,2)-1,1)];  % leave intercept unpenalized
penalty = 'enet';           % set penalty to lasso
penparam = 1;
wt = [];                    % equal observation weights
lambdastart = 0;            % find the maximum tuning parameter to start
for j=1:size(X,2)
    if (penidx(j))
    lambdastart = max(lambdastart, ...
        glm_maxlambda(X(:,j),c,y,wt,penalty,penparam,model));
    end
end
display(lambdastart);

lambda = 0.9*lambdastart;   % tuning parameter value
maxiter = [];               % use default maximum number of iterations
wt = [];                    % use default observation weights (1)
x0 = [];                    % use default start value (0)
betahat = ...               % sparse regression
    glm_sparsereg(X,y,wt,lambda,x0,penidx,maxiter,penalty,penparam,model);

figure;                     % plot penalized estimate
bar(0:length(betahat)-1,betahat);
xlabel('j');
ylabel('\beta_j');
xlim([-1,length(betahat)]);
title([penalty '(' num2str(penparam) '), \lambda=' num2str(lambda,2)]);

lambda = 0.5*lambdastart;   % tuning parameter value
betahat = ...               % sparse regression
    glm_sparsereg(X,y,wt,lambda,x0,penidx,maxiter,penalty,penparam,model);

figure;                     % plot penalized estimate
bar(0:length(betahat)-1,betahat);
xlabel('j');
ylabel('\beta_j');
xlim([-1,length(betahat)]);
title([penalty '(' num2str(penparam) '), \lambda=' num2str(lambda,2)]);

%% 
% Solution path for lasso
maxpreds = [];              % try to obtain the whole solution path
model = 'logistic';         % do logistic regression
penalty = 'enet';           % set penalty to lasso
penparam = 1;
penidx = [false; true(size(X,2)-1,1)]; % leave intercept unpenalized
wt = [];                    % equal observation weights by default
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% 
% Solution path for power (0.5)
penalty = 'power';          % set penalty function to power
penparam = 0.5;
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% 
% Compare solution paths from different penalties
maxpreds = [];              % try to obtain the whole solution paths
penalty = {'enet' 'enet' 'enet' 'power' 'power' 'log' 'log' 'mcp' 'scad'};
penparam = [1 1.5 2 0.5 1 0 1 1 3.7];
penidx = [false; true(size(X,2)-1,1)];  % leave intercept unpenalized
wt = [];                    % equal osbservation weights by default

figure;
for i=1:length(penalty)
    tic;
    [rho_path,beta_path] = ...
        glm_sparsepath(X,y,wt,penidx,maxpreds,penalty{i},penparam(i),model);
    timing = toc;
    subplot(3,3,i);
    plot(rho_path,beta_path);
    if (i==8)
        xlabel('\rho');
    end
    if (i==4)
        ylabel('\beta(\rho)');
    end
    xlim([min(rho_path),max(rho_path)]);
    title([penalty{i} '(' num2str(penparam(i)) '), ' num2str(timing,1) 's']);
end

%% Fused logistic regression
% Fused logistic regression (fusing the first 10 predictors)
D = zeros(9,size(X,2));     % regularization matrix for fusing first 10 preds
D(10:10:90) = 1;            
D(19:10:99) = -1;
display(D(1:9,1:11));
model = 'logistic';
penalty = 'enet';           % set penalty function to lasso
penparam = 1;
wt = [];                    % equal weights for all observations
tic;
[rho_path, beta_path] = glm_regpath(X,y,wt,D,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path(2:11,:));
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%%
% Same fusion problem, but with power, log, MCP, and SCAD penalty
penalty = {'power' 'log' 'mcp' 'log'};
penparam = [0.5 1 1 0];
for i=1:length(penalty)
    tic;
    [rho_path, beta_path] = glm_regpath(X,y,wt,D,penalty{i},penparam(i),model);
    timing = toc;
    subplot(2,2,i);
    plot(rho_path,beta_path(2:11,:));
    xlim([min(rho_path),max(rho_path)]);
    title([penalty{i} '(' num2str(penparam(i)) '), ' num2str(timing,1) 's']);
end

%% Sparse logistic regression (n<p)
% Simulate another sample data set (n=100, p=200)
clear;
n = 100;
p = 500;
X = randn(n,p);             % generate a random design matrix
X = bsxfun(@rdivide, X, sqrt(sum(X.^2,1))); % normalize predictors
X = [ones(size(X,1),1),X];  % add intercept
b = zeros(p+1,1);           % true signal
b(2:6) = 5;                 % first 5 predictors are 5
b(7:11) = -5;               % next 5 predictors are -5
inner = X*b;                % linear parts
prob = 1./(1+exp(-inner));
y = binornd(1,prob);        % generate binary response

%% 
% Solution path for lasso
maxpreds = 11;              % request path to the first 11 predictors
model = 'logistic';         % do logistic regression
penalty = 'enet';           % set penalty to lasso
penparam = 1;
penidx = [false; true(size(X,2)-1,1)]; % leave intercept unpenalized
wt = [];                    % equal observation weights by default
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% 
% Solution path for power (0.5)
penalty = 'power';          % set penalty function to power
penparam = 0.5;
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% Sparse loglinear (Poisson) regression
% Simulate a sample data set (n=500, p=50)
clear;
n = 500;
p = 50;
X = randn(n,p);             % generate a random design matrix
X = bsxfun(@rdivide, X, sqrt(sum(X.^2,1))); % normalize predictors
X = [ones(size(X,1),1) X];  % add intercept
b = zeros(p+1,1);           % true signal: first ten predictors are 3
b(2:6) = 3;                 % first 5 predictors are 3
b(7:11) = -3;               % next 5 predictors are -3
inner = X*b;                % linear parts
y = poissrnd(exp(inner));   % generate response from Poisson

%%
% Sparse loglinear regression at a fixed tuning parameter value
c = [];                     % constant vector is 0 by default
model = 'loglinear';        % set model to logistic
penidx = [false; true(size(X,2)-1,1)];  % leave intercept unpenalized
penalty = 'enet';           % set penalty to lasso
penparam = 1;
wt = [];                    % equal observation weights
lambdastart = 0;            % find the maximum tuning parameter to start
for j=1:size(X,2)
    if (penidx(j))
    lambdastart = max(lambdastart, ...
        glm_maxlambda(X(:,j),c,y,wt,penalty,penparam,model));
    end
end
display(lambdastart);

lambda = 0.9*lambdastart;   % tuning parameter value
maxiter = [];               % use default maximum number of iterations
wt = [];                    % use default observation weights (1)
x0 = [];                    % use default start value (0)
betahat = ...               % sparse regression
    glm_sparsereg(X,y,wt,lambda,x0,penidx,maxiter,penalty,penparam,model);

figure;                     % plot penalized estimate
bar(1:length(betahat),betahat);
xlabel('j');
ylabel('\beta_j');
xlim([0,length(betahat)+1]);
title([penalty '(' num2str(penparam) '), \lambda=' num2str(lambda,2)]);

lambda = 0.5*lambdastart;   % tuning parameter value
betahat = ...               % sparse regression
    glm_sparsereg(X,y,wt,lambda,x0,penidx,maxiter,penalty,penparam,model);

figure;                     % plot penalized estimate
bar(1:length(betahat),betahat);
xlabel('j');
ylabel('\beta_j');
xlim([0,length(betahat)+1]);
title([penalty '(' num2str(penparam) '), \lambda=' num2str(lambda,2)]);

%% 
% Solution path for lasso
maxpreds = [];              % try to obtain the whole solution path
model = 'loglinear';        % do logistic regression
penalty = 'enet';           % set penalty to lasso
penparam = 1;
penidx = [false; true(size(X,2)-1,1)]; % leave intercept unpenalized
wt = [];                    % equal observation weights by default
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% 
% Solution path for power (0.5)
penalty = 'power';          % set penalty function to power
penparam = 0.5;
tic;
[rho_path,beta_path] = ...  % compute solution path
    glm_sparsepath(X,y,wt,penidx,maxpreds,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path);
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%% 
% Compare solution paths from different penalties
maxpreds = [];              % try to obtain the whole solution paths
penalty = {'enet' 'enet' 'enet' 'power' 'power' 'log' 'log' 'mcp' 'scad'};
penparam = [1 1.5 2 0.5 1 0 1 1 3.7];
penidx = [false; true(size(X,2)-1,1)];  % leave intercept unpenalized
wt = [];                    % equal osbservation weights by default

figure;
for i=1:length(penalty)
    tic;
    [rho_path,beta_path] = ...
        glm_sparsepath(X,y,wt,penidx,maxpreds,penalty{i},penparam(i),model);
    timing = toc;
    subplot(3,3,i);
    plot(rho_path,beta_path);
    if (i==8)
        xlabel('\rho');
    end
    if (i==4)
        ylabel('\beta(\rho)');
    end
    xlim([min(rho_path),max(rho_path)]);
    title([penalty{i} '(' num2str(penparam(i)) '), ' num2str(timing,1) 's']);
end

%% Fused loglinear (Poisson) regression
% Fused loglinear regression (fusing the first 10 predictors)
D = zeros(9,size(X,2));     % regularization matrix for fusing first 10 preds
D(10:10:90) = 1;            
D(19:10:99) = -1;
display(D(1:9,1:11));
model = 'loglinear';
penalty = 'enet';          % set penalty function to lasso
penparam = 1;
wt = [];                    % equal weights for all observations
tic;
[rho_path, beta_path] = glm_regpath(X,y,wt,D,penalty,penparam,model);
timing = toc;

figure;
plot(rho_path,beta_path(2:11,:));
xlabel('\rho');
ylabel('\beta(\rho)');
xlim([min(rho_path),max(rho_path)]);
title([penalty '(' num2str(penparam) '), ' num2str(timing,2) ' sec']);

%%
% Same fusion problem, but with power, log, MCP, and SCAD penalty
penalty = {'power' 'log' 'mcp' 'scad'};
penparam = [0.5 1 1 3.7];
for i=1:length(penalty)
    tic;
    [rho_path, beta_path] = glm_regpath(X,y,wt,D,penalty{i},penparam(i),model);
    timing = toc;
    subplot(2,2,i);
    plot(rho_path,beta_path(2:11,:));
    xlim([min(rho_path),max(rho_path)]);
    title([penalty{i} '(' num2str(penparam(i)) '), ' num2str(timing,1) 's']);
end