% This function is written based on MRST code
% The core input of the system is Hydraulic Conductivity with units
% ln(cm/s)
% The simulator will automatically calculate the permeability and
% transmibilities based on input.
% Other parameters may also varry inside the simulator.
% Azarang Golmohammadi, PhD student, USC

function [pressure] = pressure_calculation(Hyd_Con);

%%=========================================================================
nx = 40; ny = 120; nz = 40;
Dx = 750; Dy = 2250; Dz = 20;
dx =  Dx/nx ; dy = Dy/ny; dz = Dz/nz ;
G = cartGrid([nx, ny, nz],[Dx ,Dy ,Dz]);
G = computeGeometry(G, 'Verbose', true);

PUMP_I =20;             %% (I,J) index of pumping well
PUMP_J = 60;
RATE = 3000*3;              %% m3/day

%%=========================================================================
rock.poro = repmat(0.36 , [G.cells.num, 1]);

visc = 1;                                                     % viscosity of water in centi-poise
dens = 1000;                                                  % density of water in kilogram/meter^3
fluid     = initSingleFluid('mu' ,    visc*centi*poise     , ...
                            'rho', dens*kilogram/meter^3);
g_gravity = 9.8;
Hyd_Con = exp(Hyd_Con);
Hyd_Con = 0.01*Hyd_Con;                                       % conversion from cm/s to m/s
perm = Hyd_Con * (0.001*visc)/g_gravity/dens;
perm = flip(permute(reshape(perm,nx,ny,nz),[3,2,1]),3);
rock.perm =perm(:);


                        
T = computeTrans(G, rock, 'Verbose', true);

%% Introduce wells/production (pumping well)

% radius     = 0.004/2;
% I = [PUMP_I];                                                                   %%%%%%%%%%%%CHANGE
% J = [PUMP_J];                                                                     %%%%%%%%%%%%CHANGE
% R = RATE*meter^3/day;                                                         %%%%%%%%%%%%CHANGE  NOW : 2.75cm^2/s
% nIW = 1:numel(I); W = [];
% for i = 1 : numel(I),
%    W = verticalWell(W, G, rock, I(i), J(i), 1, 'Type', 'rate', ...
%                     'InnerProduct', 'ip_tpf', ...
%                     'Val', R(i), 'Radius', radius, 'Comp_i', [1, 0], ...
%                     'name', ['I$_{', int2str(i), '}$']);
% end

radius     = 0.013/2;
I = [PUMP_I];                                                                   %%%%%%%%%%%%CHANGE
J = [PUMP_J];                                                                     %%%%%%%%%%%%CHANGE
R = RATE*meter^3/day;                                                         %%%%%%%%%%%%CHANGE
nIW = 1:numel(I); W = [];
load index index
cellsWell = index;
W = addWell(W, G, rock, cellsWell, 'Type', 'rate', ...
            'InnerProduct', 'ip_tpf', ...
            'Val', R, 'name', 'R1', 'Radius', radius);


%% These wells are added to desire boundary conditions
load index2 index2
cellsWell2 = index2;
W = addWell(W, G, rock, cellsWell2, 'Type', 'bhp', ...
            'InnerProduct', 'ip_tpf', ...
            'Val', 1e5, 'Dir', 'y', 'name', 'P');


load index3 index3
cellsWell3 = index3;
W = addWell(W, G, rock, cellsWell3, 'Type', 'bhp', ...
            'InnerProduct', 'ip_tpf', ...
            'Val', 5e5, 'Dir', 'y', 'name', 'P');
%%
% Once the wells are added, we can generate the components of the linear
% system corresponding to the two wells and initialize the solution
% structure (with correct bhp)

resSol = initState(G, W, 0);



%% Solve linear system
% Solve linear system construced from S and W to obtain solution for flow
% and pressure in the reservoir and the wells.
gravity off
resSol = incompTPFA(resSol, G, T, fluid, 'wells', W);

%pressure = reshape(reshape(resSol.pressure,nx,ny,nz),nx*ny*nz,1);
pressure = flip(permute(reshape(resSol.pressure,nx,ny,nz),[3,2,1]),3);
pressure = resSol.pressure;
