% Esse script vai criar os arquivos navs para rodar o ForTraCC. Esse script
% deve ser rodado para cada tipo de CAPPI (se mudar resolução, tamanho da
% grade e etc)

colormap jet;
dis2rad = 1/6378400; % 1/raio da terra em m
gra2rad = pi()/180;
rad2gra = 180/pi();

% Posição do radar
lat_radar = -22.8139;
lon_radar = -47.0562;
alt_radar = 667.8;

% Número de pontos de grade do CAPPI
nx = 200;
ny = 200;
grid_res = 1; % resolução da grade do CAPPI em km

range_max = nx*grid_res/2;

% Fiz uma grade sem a posição {0, 0}, onde fica o radar
x_axis = [linspace(-100,-1,nx/2), linspace(1,100,nx/2)].*1E3;
y_axis = [linspace(-100,-1,ny/2), linspace(1,100,ny/2)].*1E3;

% Calcula lat/lon baseado no script que o Thiago me passou
X = zeros([nx, ny]);
Y = zeros([nx, ny]);
lon = zeros([nx, ny]);
lat = zeros([nx, ny]);
lat_rad = lat_radar.*gra2rad;
lon_rad = lon_radar.*gra2rad;
for i=1:nx
    for j=1:ny
        
        X(i,j) = x_axis(i);
        Y(i,j) = y_axis(j);
        
        x0 = X(i,j);
        y0 = Y(i,j);
        
        x = x0*dis2rad;
        y = y0*dis2rad;
        
        c = sqrt(x^2 + y^2);
        
        a1 = cos(c)*sin(lat_rad);
        b1 = y*sin(c)*cos(lat_rad)/c;
        
        lat2 = asin(a1 + b1);
        lat2 = lat2*rad2gra;
        
        if(lat2 ~= 90 && lat2 ~= -90)
            
            a1 = x*sin(c);
            b1 = c*cos(lat_rad)*cos(c) - y*sin(lat_rad)*sin(c);
            
            lon2 = lon_rad + atan(a1/b1);
            lon2 = lon2*rad2gra;
        elseif(lat == 90)
            
            lon2 = lon_rad + atan(-x/y);
            lon2 = lon2*rad2gra;
            
        elseif(lat == -90)
            
            lon2 = lon_rad + atan(x/y);
            lon2 = lon2*rad2gra;
            
        end
        
        lon(i,j) = lon2;
        lat(i,j) = lat2;
        
    end
end

arq_lat = 'C:\Users\Nowcasting\SRC\SP\ForTraCC_RR\nav\nav-sr.lat';
arq_lon = 'C:\Users\Nowcasting\SRC\SP\ForTraCC_RR\nav\nav-sr.lon';
arq_masc = 'C:\Users\Nowcasting\SRC\SP\ForTraCC_RR\nav\cos-sr.bin';
flat = fopen(arq_lat,'w');
flon = fopen(arq_lon,'w');
fmasc = fopen(arq_masc,'w');
masc = 1;
for i=1:nx
    for j=1:ny
        
        fwrite(flat,lat(i,j),'single');
        fwrite(flon,lon(i,j),'single');
        fwrite(fmasc,masc,'bit16');
        
    end
end
fclose(flat);
fclose(flon);
fclose(fmasc);