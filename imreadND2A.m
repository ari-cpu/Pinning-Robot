% imreadND2: Imports images using the BioFormats package
%
% Synopsis: [vol]=imreadND2(meta,zplanes,tframes,channel,series,PixelRegion) where vol
% initially is a 6-D matrix with dimensions corresponding to width, height,
% z, t, lambda and series. Matrix is reduced at the end if singleton
% dimensions are present
%
% meta: obtained from imreadND2_meta
% zplanes:     vector specifying z-planes, e.g. [1 3 5] reads 1st, 3rd and 5th z plane
% tframes:     specifying t-frames, e.g. [1 3 5] reads 1st 3rd and 5th time step
% channel:     vector specifying channel
% series:      vector specifying series (i.e. multi-points of ND experiment)
% PixelRegion: {ROWS, COLS} subimage specified by two-element vectors ROWS
%              and COLS denoting [START STOP] or 3-elements vectors denoting
%              [START INCREMENT STOP].
%
% Enno Oldewurtel
%
% Example:
% if ND2 hold a 2x2 multipoint array of 100px square images with a time 
% series of 10 steps
%
% image = imreadND2;
% where image is a 4D object with size: 100, 100, 10, 4
%
% meta = imreadND2_meta;
% image = imreadND2(meta,1,[2 4 6 8 10],1,[1 2],{[26,75],[26,75]});
% where image is a 4D object with size: 100, 100, 5, 2
% this image holds every 2nd image in the time series and the first two
% multi-points. All images are cropped to the middle 50x50 px region
%
%modified from bfopen.m

function [vol]=imreadND2A(meta,idx,channel)

if nargin < 1
    meta=imreadND2_meta;
end

% specify PixelRegion
if nargin < 6
    PixelRegion={[1,meta.height],[1,meta.width]};
end
    r1=PixelRegion{1}(1)-1;
    c1=PixelRegion{2}(1)-1;
    height=PixelRegion{1}(end)-PixelRegion{1}(1)+1;
    width=PixelRegion{2}(end)-PixelRegion{2}(1)+1;
    if r1>0 || c1>0 || height<meta.height || width<meta.width
        subImage=true;
        % EO 2015-05-11: to keep syntax similar to imread, introduce
        % increment. N.b. downsampling only done in a second step!
        if length(PixelRegion{1})==3
            rIncr=PixelRegion{1}(2);
        else
            rIncr=1;
        end
        if length(PixelRegion{2})==3
            cIncr=PixelRegion{2}(2);
        else
            cIncr=1;
        end
        h0=length(1:rIncr:height);
        w0=length(1:cIncr:width);
    else
        subImage=false;
        h0=height;
        w0=width;
    end


    series=1:meta.series;

%     channel=1:meta.channels; %TC 4.10.2018 preselect for multichannel images

    tframes=1:meta.tframes;

    zplanes=1:meta.zsize;

    
channel=channel-1;
zplane=zplanes-1;
tframe=tframes-1;
series=series-1;

% % check MATLAB version, since typecast function requires MATLAB 7.1+
canTypecast = 1;
% canTypecast = versionCheck(version, 7, 1);


% vol=zeros(height,width,length(zplane)*length(tframe));
BitDepth=meta.pointer.getBitsPerPixel;
if BitDepth==12 || BitDepth==14
    BitDepth=16;
end
vol=zeros(h0,w0,length(zplane),length(tframe),length(channel),length(series),['uint' num2str(BitDepth)]);
zahler_series=0;
for m=1:length(series)
    
    zahler_series=zahler_series+1;
    meta.pointer.setSeries(series(m));
    zahler_ch=0;
    for k=1:length(channel)
        
        zahler_ch=zahler_ch+1;
        zahler_t=0;
        for j=1:length(tframe)
            
            zahler_t=zahler_t+1;
            zahler_z=0;
            for i=1:length(zplane)
            %['importing file via bioFormats\\ ',num2str(100*zahler/(length(tframe)*length(zplane))),'%']
                
                index=meta.pointer.getIndex(zplane(i),channel(k),tframe(j));
                if ~subImage
                    plane = meta.pointer.openBytes(index);
                else
%                 crop region?
                    plane = meta.pointer.openBytes(index,c1,r1,width,height);
                end
                zahler_z=zahler_z+1;

%                 anyarr=0;
%                 offset=0;
%                 while anyarr==0
                
                % taken from bfGetPlane.m
                if meta.format.sgn || ~canTypecast
                    arr=loci.common.DataTools.makeDataArray2D(plane, ...
                            meta.format.bpp, meta.format.fp, meta.format.little, meta.height);
                else
                    arr = loci.common.DataTools.makeDataArray(plane, ...
                            meta.format.bpp, meta.format.fp, meta.format.little);
                end
                
%                 anyarr=any(arr);
%                 if ~anyarr & tframe(j)-offset-1>=0
%                     offset=offset+1;
%                     index=meta.pointer.getIndex(zplane(i),channel(k),tframe(j)-offset);
%                     plane = meta.pointer.openBytes(index);
%                 end
%                 end
                
                %Java does not have explicitly unsigned data types;
                %hence, we must inform MATLAB when the data is unsigned
                if ~meta.format.sgn
                    if canTypecast
                        arr = typecast(arr,['uint',num2str(BitDepth)]);
                    else
                        mask = arr < 0;
                        adjusted = arr(mask) + 2^BitDepth / 2;
                        adjusted = eval(['uint',num2str(BitDepth),'(adjusted)']);
                        adjusted = adjusted + 2^BitDepth / 2;
                        arr      = eval(['uint',num2str(BitDepth),'(arr)']);
                        arr(mask)= adjusted;
                    end
                end
                if ~(meta.format.sgn || ~canTypecast)
                    shape=[width,height];
%                     shape=[400,200];
                    arr = reshape(arr,shape)';
                end
                    
                
                
                
%                 
%                 arr = loci.common.DataTools.makeDataArray2D(plane, ...
%                             meta.format.bpp, meta.format.fp, meta.format.little, meta.height);
%                         
%                         % 2013-08-05 EO: trouble with grayvalues above (2^16)/2 turning negative
%                           % since arr is signed, this probably make sense,
%                           % but loci should best give out unsigned only...
%                       if ~meta.format.sgn
%                           if ~isempty(find(arr<0,1))
%     %                         %old:
%     %                         arr=double(arr);
%     %                         arr(arr<0)=2^BitDepth + arr(arr<0);
%                             %new approach:    
%                             mask = arr < 0;
%                             adjusted = arr(mask) + 2^BitDepth / 2;
%                             adjusted = eval(['uint',num2str(BitDepth),'(adjusted)']);
%                             adjusted = adjusted + 2^BitDepth / 2;
%                             arr      = eval(['uint',num2str(BitDepth),'(arr)']);
%                             arr(mask)= adjusted;
%                           end
%                       end
%                 dipshow(5,arr);diptruesize(50)        

                if subImage && (length(PixelRegion{1})==3 || length(PixelRegion{2})==3)
                    vol(:,:,zahler_z,zahler_t,zahler_ch,zahler_series)=arr(1:rIncr:end,1:cIncr:end);
                else
                    vol(:,:,zahler_z,zahler_t,zahler_ch,zahler_series)=arr;
                end

            end
        end
    end
end
% Note 6D object is squeezed and all singleton dimensions are removed in
% the following step. This may be confusing in case you specify only specific
% frames, e.g. where you sometimes want 1 plane, sometimes 2 planes the
% output will return objects with varying dimensions
% vol=squeeze(vol);    
    
end    


function [result] = versionCheck(v, maj, min)

tokens = regexp(v, '[^\d]*(\d+)[^\d]+(\d+).*', 'tokens');
majToken = tokens{1}(1);
minToken = tokens{1}(2);
major = str2double(majToken{1});
minor = str2double(minToken{1});
result = major > maj || (major == maj && minor >= min);

end
            
  
            
     % following does some mirroring, probably to with how matlab treats
     % in columns first?

                
%                 % taken from bfGetPlane.m
%                 if meta.format.sgn || ~canTypecast
%                     arr=loci.common.DataTools.makeDataArray2D(plane, ...
%                             meta.format.bpp, meta.format.fp, meta.format.little, meta.height);
%                 else
%                     arr = loci.common.DataTools.makeDataArray(plane, ...
%                             meta.format.bpp, meta.format.fp, meta.format.little);
%                 end
%                 
%                 %Java does not have explicitly unsigned data types;
%                 %hence, we must inform MATLAB when the data is unsigned
%                 if ~meta.format.sgn
%                     if canTypecast
%                         arr = typecast(arr,['uint',num2str(BitDepth)]);
%                     else
%                         mask = arr < 0;
%                         adjusted = arr(mask) + 2^BitDepth / 2;
%                         adjusted = eval(['uint',num2str(BitDepth),'(adjusted)']);
%                         adjusted = adjusted + 2^BitDepth / 2;
%                         arr      = eval(['uint',num2str(BitDepth),'(arr)']);
%                         arr(mask)= adjusted;
%                     end
%                 end
%                 if ~(meta.format.sgn || ~canTypecast)
%                     shape=[meta.width,meta.height];
%                     arr = reshape(arr,shape)';
%                 end
                    

        
   
   
   
   
   
            
            