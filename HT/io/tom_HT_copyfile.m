function tom_HT_copyfile(sourcefilename,type,projectname,outfilename)

settings = tom_HT_settings();

outputdir = [settings.data_basedir '/' projectname];

switch type
    case 'mtf'
        outputdir = [outputdir '/mtfs'];  
    case 'micrograph'
        outputdir = [outputdir '/micrographs'];
        
    otherwise
        error('Type not supported in tom_HT_copyfile.');
end


[status,message] = copyfile(sourcefilename,[outputdir '/' outfilename],'f');
if status ~= 1
    error(message);
end

[status,message] = fileattrib([outputdir '/' outfilename],'+w','u g');
if status ~= 1
    error(message);
end