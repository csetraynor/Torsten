// Solve two compartment model using built-in analytical solution 

data{
  int<lower = 1> nt;         // number of events
  int<lower = 1> nObs;       // number of observation
  int<lower = 1> iObs[nObs]; // index of observation
  
  // NONMEM data
  int<lower = 1> cmt[nt];
  int evid[nt];
  int addl[nt];
  int ss[nt];
  real amt[nt];
  real time[nt];
  real rate[nt];
  real ii[nt];
  
  vector<lower = 0>[nObs] cObs;  // observed concentration (Dependent Variable)
}

transformed data{
  vector[nObs] logCObs = log(cObs);
  int nTheta = 5; // number of ODE parameters in Two Compartment Model
  int nCmt = 3;   // number of compartments in model

  // Since we're not trying to evaluate the bioavailability (F) and 
  // the lag times, we declare them as data.
  real biovar[nCmt] = {1.0, 1.0, 1.0};
  real tlag[nCmt] = {0.0, 0.0, 0.0};
}

parameters{
  real<lower = 0> CL;
  real<lower = 0> Q;
  real<lower = 0> V1;
  real<lower = 0> V2;
  real<lower = 0> ka;
  real<lower = 0> sigma;
}

transformed parameters{
  real theta[nTheta];  // ODE parameters
  row_vector<lower = 0>[nt] cHat;
  row_vector<lower = 0>[nObs] cHatObs;
  matrix<lower = 0>[nCmt, nt] x; 

  theta[1] = CL;
  theta[2] = Q;
  theta[3] = V1;
  theta[4] = V2;
  theta[5] = ka;

  x = pmx_solve_twocpt(time, amt, rate, ii, evid, cmt, addl, ss,
                       theta, biovar, tlag);

  cHat = x[2, ] ./ V1; // we're interested in the amount in the second compartment 

  cHatObs = cHat[iObs]; // predictions for observed data recors
}

model{
  CL ~ lognormal(log(10), 0.25);
  Q ~ lognormal(log(15), 0.5);
  V1 ~ lognormal(log(35), 0.25);
  V2 ~ lognormal(log(105), 0.5);
  ka ~ lognormal(log(2.5), 1);
  sigma ~ cauchy(0, 1);

  logCObs ~ normal(log(cHatObs), sigma);
}

generated quantities{
  real cObsPred[nObs];

  for(i in 1:nObs){
    cObsPred[i] = exp(normal_rng(log(cHatObs[i]), sigma));
  }
}
