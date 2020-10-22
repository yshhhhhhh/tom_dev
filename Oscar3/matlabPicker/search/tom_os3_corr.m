function [res options] = tom_os3_corr(img,template,options)
%tom_os3_corr
%   
%   tom_os3_corr calculates the normalized cross correlation coefficent
%   of the search image img and the given template. The size of img must be
%   greater than or equal as the template size.
%   
%   Depending on the option structure the returned correlation map is
%   calculated by the Fast Normalized Cross Correlation Function according to
%   Roseman.
%   Other possible correlation variants are 
%   MCF - Mutual Correlation Filter
%   POF - Phase only filter
% 
%   The options strucure is generated by tom_os3_readOptions and the
%   options.correlation attribute specifies the behaviour of this function.
% 
% 
%   tom_os3_corr(img,template,options)
%
%PARAMETERS
%
%  INPUT
%   img         - the search image / volume
%   template    - 
%   options     - optional. If not given 
%   
%  
%  OUTPUT
%   res         - the resulting correlation map
%   options     - this updated version of the options structure contains
%                 the statistics (mean and std) of the search image and its
%                 calculated fourier transform. 
%EXAMPLE
%   tom_amira_createisosurface(...);
%   creates ...
%
%REFERENCES
%
%SEE ALSO
%   ...
%
%   created by TH2 07/07/07
%   updated by ..
%
%   Nickell et al., 'TOM software toolbox: acquisition and analysis for electron tomography',
%   Journal of Structural Biology, 149 (2005), 227-234.
%
%   Copyright (c) 2004-2007
%   TOM toolbox for Electron Tomography
%   Max-Planck-Institute of Biochemistry
%   Dept. Molecular Structural Biology
%   82152 Martinsried, Germany
%   http://www.biochem.mpg.de/tom

img      = single(img);
template = single(template);

imageSize = numel(img);
templateSize= numel(template);

if(nargin <3 || ~isfield(options,'correlation') || ~isfield(options.correlation,'type'))
    options.correlation.type = 'FLCF';
    options.correlation.calculationAvailable = false;
end;


% res is either nccc or mcf or pof
res = zeros(size(img),'single');

if(~isfield(options.correlation,'calculationAvailable'))
    options.correlation.calculationAvailable = false;
end;

norm = options.correlation;
%%
if(strcmp(norm.type,'FLCF'))
    
%default if no flag set
%norm according to Roseman paper in Ultramicroscopy 94    
%%  generate innerMask for normalization
    if(~isfield(options.correlation,'mask'))
         [innerMask innerMaskSize]= tom_os3_sphereMask(template);
%          innerMask = ones(size(template),'single');
%          innerMaskSize = length(template(:));
       
        options.correlation.mask = innerMask;
        options.correlation.maskSize = innerMaskSize;
        norm.mask = innerMask;
        norm.maskSize = innerMaskSize;
    else
        innerMask = options.correlation.mask;
        innerMaskSize = options.correlation.maskSize;
        
    end;
    
    
%%  if statistics of the search volume have not been calculated yet, calculate now
    if(~ norm.calculationAvailable)
%         %paste innerMask into a volume of same size as volume
%         mask = zeros(size(img),'single');
%         mask = tom_os3_pasteCenter(mask,innerMask);
        %calculate mean under template for each pixel
        [imageMean a fimage fmask] = tom_os3_mean(img,innerMask);
%         [a imageMean imageSTD b]= norm_inside_mask(img,mask);
        %calculate STD under Template for each image pixel
        imageSTD = tom_os3_std(img,imageMean,innerMask,innerMaskSize,fimage,fmask);
        
%%      avoid numeric artefacts 1        
        if(mean(imageSTD(:))<0.01)
            img = tom_norm(img+1000,'mean0+1std');
            [imageMean a fimage fmask]= tom_os3_mean(img,innerMask);

            imageSTD = tom_os3_std(img,imageMean,innerMask,innerMaskSize,fimage,fmask);

            template = tom_norm((template*1000+1000).*innerMask,'mean0+1std');   
        end;
%%    avoid numeric artefacts 2
        if(mean(imageSTD(:))<0.01)

            disp('You are using an image with too few features. The standart deviation of the image is almost zero!');
            disp('The image will be normalized to mean=0 and std=1! Check for numeric artefacts after the processing.');
            disp('Pixels with very low std will be marked their result will be set to 0.');
            hotpixels = find(imageSTD(:)<0.05);          
        end;

        
%%  else use already calculated statistics and fourier transform of the vol
    else
        %if correction map has already been calculated, take the old
        %results
        imageMean = norm.imageMean;
        imageSTD = norm.imageSTD;
        
        fimage = norm.fimage;
    end;
   
%%  calculate template statistics 
    if(~isfield(norm,'templateMean') || ~ norm.calculationAvailable)
          [tmp templateMean templateSTD] = tom_os3_normUnderMask(template,innerMask);

    else
        %use a priori calculated template statistics
        templateMean = norm.templateMean;
        templateSTD  = norm.templateSTD;
    end;
    
%     tom_imagesc(template.*innerMask);figure;tom_imagesc(img);drawnow;
%     ginput(1);
%%  do the correlation in fourierSpace
    ftemplate = fftn(tom_os3_pasteCenter(zeros(size(img)),template.*innerMask));
    c =  (fimage) .* conj(ftemplate);
    numerator = single(real(ifftshift(ifftn(c)) /innerMaskSize)*10000) ; %<- wichtig, durch templateSize/maskSize teilen!!!! sonst keine 1
%     tom_dev(numerator);

%%  calculate nominator and denominator for normalization
    numerator = numerator - single(imageMean*10000*templateMean); 
    denominator = single(templateSTD * imageSTD*10000); 

%     tom_dev(numerator);
%     tom_dev(denominator);    
%%  set very small values in the nominator to 0 and do not divide by 0

    %set very small numerator values to 0
%     if(~isfield(options.correlation,'isAutoc') || ~options.correlation.isAutoc)
%         smallValues = find(abs(numerator) < eps*10000);
%         numerator(smallValues) = 0;
%     end;
    nonzero = find(abs(denominator-eps) > eps);
%%  calculate normalized cross correlation coefficient if image sizes
%   differ use voxels where denominator > 0
    if(imageSize ~= templateSize)
        res(nonzero) = single(numerator(nonzero) ./ denominator(nonzero)); 
    else
        res = single(numerator ./ denominator);
    end;
%     res = single(numerator ./ denominator);
%%  large values(nummerical errors) must be deleted
    

    if(exist('hotpixels') )        
        res(hotpixels) = 0;
    end;
%%  return structure
    norm.imageMean = imageMean;
    norm.imageSTD = imageSTD;
    norm.templateMean = templateMean;
    norm.templateSTD = templateSTD;
    norm.calculationAvailable = true;
    norm.fimage = fimage;
    
    options.correlation = norm;
%%    
elseif(strcmp(norm.type,'MCF'))
%correlation according to vanHeel paper - Mutual Correlation Filter    & Foerster Diss 
    

    if(~norm.calculationAvailable || ~isfield(norm,'mcfImage'))
        fimage = fftn(img) ;
        try
            fimage = fimage ./ sqrt(abs(fimage));
        catch
            nonzero = find(abs(fimage) > 0);
            fimage(nonzero) = fimage(nonzero) ./ sqrt(abs(fimage(nonzero)));        
        end;

        mcfImage = ifftn(fimage);
    else
        mcfImage = norm.mcfImage;
    end;
    
    
    ftemplate = fftn(template);
    try
        ftemplate = (ftemplate) ./ sqrt(abs(ftemplate));    
    catch
        nonzero = find(abs(ftemplate) > 0);
        ftemplate(nonzero) = (ftemplate(nonzero)) ./ sqrt(abs(ftemplate(nonzero)));    
    end;
    
%%  correlate     
    options.correlation.type = 'FLCF';
    [res options] = tom_os3_corr(mcfImage,ifftn(ftemplate),options);
    options.correlation.mcfImage = mcfImage;
    options.correlation.type = 'MCF';

%%
elseif(strcmp(norm.type,'POF'))        
%Phase Only Filter according to 'Correlation Pattern Recognition p.???' & Foerster Diss   
    if(~norm.calculationAvailable || ~isfield(norm,'pofImage'))
        fimage = fftn(img) ;
        nonzero = find(abs(fimage) > 0);
        fimage(nonzero) = fimage(nonzero) ./ abs(abs(fimage(nonzero)));
        pofImage = ifftn(fimage);
    else
        pofImage = norm.pofImage;
    end;
    
    
    ftemplate = fftn(template);
    nonzero = find(abs(ftemplate) > 0);
    ftemplate(nonzero) = (ftemplate(nonzero)) ./ (abs(ftemplate(nonzero)));
    
%%  correlate     
    options.correlation.type = 'FLCF';
    [res options] = tom_os3_corr(pofImage,ifftn(ftemplate),options);
    options.correlation.pofImage = pofImage;
    options.correlation.type = 'POF';
    
end;



function [normed_vol mea st n]=norm_inside_mask(vol,mask)

mask=mask~=0;

n=sum(sum(sum(mask~=0)));
mea=sum(sum(sum((vol.*mask).*(vol~=0))))./n;
st=sqrt(sum(sum(sum((((mask==0).*mea)+(vol.*mask) -mea).^2)))./n);
normed_vol=((vol-mea)./st).*mask;