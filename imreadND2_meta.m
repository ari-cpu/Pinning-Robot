% imreadND2_meta: Acquires meta data from image file. In particular it
% creates a pointer, which makes it very easy to retrieve specifc planes
% from the image. This is then done in imreadND2
%
% Synopsis: meta=imreadND2_meta(datname)
%
% datname: file location of ND2 file
%
% Enno Oldewurtel
%
% Example:
% if ND2 hold a 2x2 multipoint array of 100px square images with a time 
% series of 10 steps
%
% meta = imreadND2_meta
% meta = 
%       datname: image file location
%       pointer: points to the image file
%        format: info about PixelType, BytesPerPixel, FloatingPoint, Little
%                and Signed
%         width: width of one image plane
%        height: height of one image plane
%         zsize: number of slices in z-stack
%       tframes: number of steps in time series
%      channels: number of channels, e.g. BF, lambda1, lambda2, ...
%        series: number of images in a series, e.g. a 2x2 multipoint grid
%                array 4 images in a series, indexed row-wise
%           raw: all metadata as java hashtable
%   
%To use the function, you have to download bioformats_package.jar here: http://www.loci.wisc.edu/bio-formats/downloads
%make sure to have copied the file loci_tools.jar, in the folder where the
%function is placed (or to your work folder)
%
% For static loading, you can add the library to MATLAB's class path:
%     1. Type "edit classpath.txt" at the MATLAB prompt.
%     2. Go to the end of the file, and add the path to your JAR file
%        (e.g., C:/Program Files/MATLAB/work/loci_tools.jar).
%     3. Save the file and restart MATLAB.
function meta=imreadND2_meta(datname,meta)


if nargin < 1
    [file, path]=uigetfile('*.*');
    %if cancel is pushed, then return.
    if (isscalar(file) == 1) && (isscalar(path) == 1); 
        return; 
    end
    meta.datname=fullfile(path,file);
else
    meta.datname=datname;
end
tic
% path = fullfile(fileparts(mfilename('fullpath')), 'loci_tools.jar');
path = fullfile(fileparts(mfilename('fullpath')), 'bioformats_package.jar');
if isempty(find(strcmp(javaclasspath,path),1))
    javaaddpath(path);
end

if exist('lurawaveLicense')
    path = fullfile(fileparts(mfilename('fullpath')), 'lwf_jsdk2.6.jar');
    javaaddpath(path);
    java.lang.System.setProperty('lurawave.license', lurawaveLicense);
end

% check MATLAB version, since typecast function requires MATLAB 7.1+
canTypecast = versionCheck(version, 7, 1);

% check Bio-Formats version, since makeDataArray2D function requires trunk
bioFormatsVersion = char(loci.formats.FormatTools.VERSION);
isBioFormatsTrunk = versionCheck(bioFormatsVersion, 5, 0);

% % initialize logging
% loci.common.DebugTools.enableLogging('INFO');
loci.common.DebugTools.enableLogging('WARN');
% If you use 'WARN' or 'ERROR' instead of 'INFO', that should
% substantially reduce the amount of output that you see.

meta.pointer = loci.formats.ChannelFiller();
meta.pointer = loci.formats.ChannelSeparator(meta.pointer);

meta.pointer.setMetadataStore(loci.formats.MetadataTools.createOMEXMLMetadata());

% 2014-03-28 EO: person on the openmicroscopy mailing list had a problem
% with setID performance (ImageProcessorReader.setId performance). Just in
% case this slows things down here, too, I added not to group files
% meta.pointer.setGroupFiles(false);

% metareadpointer
% disp('before setID');
% tstart=tic;
meta.pointer.setId(meta.datname);
% elapsed=toc(tstart);
% disp([num2str(elapsed) ' sec elapsed for setID']);
% metareadpointer

meta.format.pixelType = meta.pointer.getPixelType();

meta.format.bpp = loci.formats.FormatTools.getBytesPerPixel(meta.format.pixelType);
meta.format.fp = loci.formats.FormatTools.isFloatingPoint(meta.format.pixelType);
meta.format.little = meta.pointer.isLittleEndian();
meta.format.sgn = loci.formats.FormatTools.isSigned(meta.format.pixelType);

    meta.width = meta.pointer.getSizeX();
    meta.height = meta.pointer.getSizeY();
    meta.zsize=meta.pointer.getSizeZ();
    meta.tframes=meta.pointer.getSizeT();
    meta.channels=meta.pointer.getSizeC();
    meta.series=meta.pointer.getSeriesCount();

% disp('before getMetadata');
% tstart=tic;
    metadataList = meta.pointer.getGlobalMetadata();
% elapsed=toc(tstart);
% disp([num2str(elapsed) ' sec elapsed for getGlobalMetadata']);        
    %m=r.getMetadataStore();
    
    subject = metadataList.get('parameter scale');
    subject;
    if ~isempty(subject)% if possible pixelsizes are added
    voxelsizes=str2num(subject);
   
    meta.voxelsizes=voxelsizes;
    
    if voxelsizes>1
    meta.psizeX=voxelsizes(2);
    meta.psizeY=voxelsizes(3);
    meta.psizeZ=voxelsizes(4);
    meta.psizeT=voxelsizes(5);
        
    end
    
    end 
    
    meta.raw=metadataList;%metadata as java hashtable
% tstart=tic;
    meta.rawSeries=meta.pointer.getSeriesMetadata();
% elapsed=toc(tstart);
% disp([num2str(elapsed) ' sec elapsed for getSeriesMetadata']);          
    meta.datname=meta.pointer.getCurrentFile();
    
    meta.bioFormatsVersion=bioFormatsVersion;
    meta.isBioFormatsTrunk=isBioFormatsTrunk;
    
end
    
    
    
function [result] = versionCheck(v, maj, min)

tokens = regexp(v, '[^\d]*(\d+)[^\d]+(\d+).*', 'tokens');
majToken = tokens{1}(1);
minToken = tokens{1}(2);
major = str2num(majToken{1});
minor = str2num(minToken{1});
result = major > maj || (major == maj && minor >= min);
end    
    
            
            
            
            
            
  
            
            

        
   
   
   
   
   
            
            