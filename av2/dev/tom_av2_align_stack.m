function [align2d new_ref]=tom_av2_align_stack(stack_path,ref_path,align2d,stack_alg_path,ref_alg_path,filter_param,paraell_param,iterations,demo)
%
% [align2d new_ref]=tom_av2_align_stack(stack_path,ref_path,align2d,stack_alg_path,ref_alg_path,filter_param,paraell_param,iterations,demo)
% 
% performs iterative rotational, translational alignment of an image stack (im) relative to reference stack (ref)
%
%
% Input:    stack_path:         path reference stack 
%           ref_path:           path image stack to be aligned  
%           align2d:            path alignment structure 
%           stack_alg_path:     path for the aligned stack  ... use '' for
%           no output
%           ref_alg_path:       path for the new reference stack ... use ''for no output
%           filter_param:       contains filter and mask structures: 
%                                                filter_param.mask.classify1 
%                                                filter_param.mask.classify2
%                                                filter_param.mask.align 
%                                                filter_param.mask.ccf_rot
%                                                filter_param.mask.ccf_trans
%                                                filter_param.filter.classify
%                                                filter_param.filter.align
%                                                
%                                                
%                                                filter_st -structure
%                                                filter_st.Apply:  1 apply filter, 2 use default values, 0 not
%                                                filter_st.Value:  vector with parameters [low, high, smooth ...]
%                                                filter_st.Method: i.e. 'circ', 'quadr', 'bandpass'
%                                                filter_st.Space: 'real' or 'fourier'
%                                                filter_st.Times: 'apply filter n-times                                  
%
%
%                                                mask_st -structure
%                                                mask_st.Apply:  1 built mask according to the struct values, 2 use default values, 0 create ones
%                                                mask_st.Value:  vector with parameters [size,radius,smooth,center ...]
%                                                mask_st.Method: 'sphere' 'sphere3d' 'cylinder3d' 'rectangle'  
%                                                
%
%
%            paraell_param:        structure for paraell processing ... use '' for one CU
%                                            
%                                                paraell_param.jobmanager:      Name of the jobmanager
%                                                paraell_param.packageloss:     maximum allowed package loss [0..1]
%                                                paraell_param.number_of_tasks: number of tasks in which the job will be split
%                                                paraell_param.workers.min:     minimum number of workers to use
%                                                paraell_param.workers.max:     maximum number of workers to use
%                                                paraell_param.timeout:         timeout value for each task in seconds
%                                                paraell_param.restart_workers: 1 = restart workers bef
%
%           iterations            [refinement alignment]   
%
%
%           demo:                 flag (1: show multiref, 2: show alignment  3: show multiref+alignment  0: off) for demo mode via graphical interface
%                                 works only with on CU 
%                               
%
%
%           Output:             align2d           alignment structure with updated values for translation and rotation         
%                               new_ref           aligned referece stack                       
%           
%
% Example:  
%           
%
% 
%
% 24/01/06, FB 

%parse inputs!
h=tom_reademheader(stack_path);


switch nargin
    case 2
        align2d='';
        stack_alg_path='';
        ref_alg_path='';
        filter_param=tom_av2_build_filter_param([h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');
        paraell_param=tom_build_paraell_param('');
        iterations=[1 1];
        demo=0;
    case 3
        stack_alg_path='';
        ref_alg_path='';
        filter_param=tom_av2_build_filter_param([h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');
        paraell_param=tom_build_paraell_param('');
        iterations=[1 1];
        demo=0;
    case 4
        ref_alg_path='';
        filter_param=tom_av2_build_filter_param([h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');
        paraell_param=tom_build_paraell_param('');
        iterations=[1 1];
        demo=0;
    case 5
        filter_param=tom_av2_build_filter_param([h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');
        paraell_param=tom_build_paraell_param('');
        iterations=[1 1];
        demo=0;
    case 6
        paraell_param=tom_build_paraell_param('');
        iterations=[1 1];
        demo=0;
    case 7
        iterations=[1 1];
        demo=0;
    case 8
        demo=0;
    case 9
        
    otherwise
        error('wrong number of parameters!');
end;
  
if (isempty(filter_param)==1)
    filter_param=tom_av2_build_filter_param('',[h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');
end;

filter_param=tom_av2_build_filter_param(filter_param,[h.Header.Size(1) h.Header.Size(2)],'default','tom_av2_multi_ref_alignment');

if (isempty(paraell_param)==1)
    paraell_param=tom_build_paraell_param('');;
end;
paraell_param=tom_build_paraell_param(paraell_param);

if (isempty(iterations)==1)
    iterations=[1 1];
end;

if (isempty(align2d)==0)
    if (isstruct(align2d)==0)
        load(align2d);
    end;
end;

[path_tmp name_tmp ext_ref_alg_path]=fileparts(ref_alg_path);
ref_alg_path=[path_tmp '/' name_tmp];
if (isempty(ext_ref_alg_path)==1)
    ext_ref_alg_path='.em';
end;



error_m=0;
correction_flag='post_correction';
shift_corr_flag=1;
h=tom_reademheader(stack_path);
size_stack=h.Header.Size;
h=tom_reademheader(ref_path);
size_ref_stack=h.Header.Size';
iter_num=1;
disp_flag=0;
angular_scan=0;
num_of_tasks=paraell_param.number_of_tasks;
max_lost_packages=round(paraell_param.packageloss.*num_of_tasks);
jobmanager=paraell_param.jobmanager;
number_of_alg_iter=iterations(1);
number_of_alg_steps=iterations(2);
mask=tom_create_mask(filter_param.mask.classify1);

%check for absolute path
tmp_path=fileparts(ref_alg_path);
if (isempty(tmp_path)==1)
    if (num_of_tasks > 1)
        ref_alg_path=[pwd '/' ref_alg_path];
    end;
end;

tmp_path=fileparts(stack_path);
if (isempty(tmp_path)==1)
    if (num_of_tasks > 1)
        stack_path=[pwd '/' stack_path];
    end;
end;

tmp_path=fileparts(ref_path);
if (isempty(tmp_path)==1)
    if (num_of_tasks > 1)
        ref_path=[pwd '/' ref_path];
    end;
end;



step=1;

for iiii=1:10000

    
    % initialize structure for class averages
    avg_st_im=zeros(size_ref_stack);
    avg_st_num=zeros(1,size_ref_stack(3));

    
    
    if (num_of_tasks==1)
        %just rip the local horst hoe hoe
        [class_st]=tom_av2_multi_ref_alignment(stack_path,ref_path,filter_param,correction_flag,number_of_alg_iter,[1 size_stack(3)],0,demo);
        lost=0;
    else

        [a,b]=system(['chmod ugo+rwx ' stack_path]);
        [a,b]=system(['chmod ugo+rwx ' ref_path]);
        jm = findResource('jobmanager','name',jobmanager);
        result_p=tom_get_paraell_results(jm,'hosts');
        disp(['classifying on ' num2str(size(result_p,1)) ' hosts']);
        for iii=1:size(result_p,1)
            disp(result_p{iii});
        end;
        clear('result_p');
        j = createJob(jm,'Name','demojob');
        set(j,'FileDependencies',{'/fs/bmsan/apps/tom_dev/av2/tom_av2_multi_ref_alignment.m'})
        packages=tom_calc_packages(num_of_tasks,size_stack(3));
        for i=1:num_of_tasks
            createTask(j,@tom_av2_multi_ref_alignment,1,{stack_path,ref_path,filter_param,correction_flag,number_of_alg_iter,packages(i,1:2),i});
        end;
        submit(j);
        %tom_disp_paraell_progress(j,packages(:,3));
        waitForState(j);
        out = getAllOutputArguments(j);
        [result_p errorsum]=tom_get_paraell_results(j);
        if (errorsum > 0);
            for i=1:size(result_p,1)
                disp(['Hostname: ' result_p{i,1} '  Error: ' result_p{i,2}]);
            end;
        end;
        destroy(j);
        [class_st lost error_m]=built_class_st(out,packages,max_lost_packages);

        if (error_m==1)
            error_m=0;
            step=step-1;
            continue;
        end;

        ref_path=ref_alg_path;
    end;

   
    %command window print
    store.end=size(class_st,2); store.num_of_mesure=1;  store.mesured=0;
    [store]=tom_disp_estimated_time(store,'start','averaging');

    
    if (isempty(stack_alg_path)==0)
        num=get_class_numbers(class_st,size_ref_stack(3));
        for ii=1:size_ref_stack(3)
            tom_emwritec([stack_alg_path],[size_stack(1) size_stack(2) num(ii)],'new');
        end;
    end;

    for i=1:size(class_st,2)
        ref_nr=class_st(1,i);
        ccc=class_st(2,i);
        shift=[class_st(3,i) class_st(4,i)];
        rot=round(class_st(5,i));

        if  (ref_nr~=-1)

            %read particle
            part=tom_emread([stack_path],'subregion',[1 1 i],[size_stack(1)-1 size_stack(2)-1 0]);
            part=part.Value;
           % part=part.*mask;
            
            %norm particle
            %part=(part-mean2(part))./mean2(part);
            
            if (isempty(stack_alg_path)==0 | nargout < 2 | isempty(ref_alg_path) )
                
                part=tom_shift(tom_rotate(part,rot),[shift]);
                avg_st_im(:,:,ref_nr)=avg_st_im(:,:,ref_nr)+part;
                avg_st_num(ref_nr)=avg_st_num(ref_nr)+1;
                
                 if (isempty(stack_alg_path)==0)
                    tom_emwritec([stack_alg_path],part,'subregion',[1 1 avg_st_num(ref_nr)],[size_stack(1) size_stack(1) 1]);
                 end;
            end;
            align2d(1,i).ref_class=ref_nr;
            align2d(1,i).shift=shift;
            align2d(1,i).angle=rot;
            align2d(1,i).ccc=ccc;
        else
            %package got lost or classification failed
            align2d(1,i).ref_class=-1;
            align2d(1,i).shift=[];
            align2d(1,i).angle=0;
            align2d(1,i).ccc=0;
        end;

        %command window print
        store.i=i;
        [store]=tom_disp_estimated_time(store,'estimate_time');
%        [store]=tom_disp_estimated_time(store,'progress');
    end;
    
     
    %norm new ref stack according to the number particles
    for n=1:size_ref_stack(3)
        avg_st_im(:,:,n)=avg_st_im(:,:,n)./avg_st_num(n);
    end;
    
    
    if (isempty(ref_alg_path)==0 & (strcmp(ref_alg_path,'tmpXX')==0))
        ref_path=[ref_alg_path '_' num2str(step) ext_ref_alg_path];
        tom_emwrite([ref_alg_path '_' num2str(step) ext_ref_alg_path],avg_st_im);
    else
        tom_emwrite([pwd '/tmpXX'],avg_st_im);
        ref_path=[pwd '/tmpXX'];
    end;
    
    
    new_ref=avg_st_im;    
    step=step+1;
    if (step > number_of_alg_steps)
        break;
    end;
    
    save('align_tmp','align2d');
end;



disp('end');

function [class_st lost error_m]=built_class_st(out,packages,max_lost_packages)

error_m=0;
zz=1;
lost=0;

if (isempty(out)==1)
    error_m=1;
    disp(['ERROR: All Packages lost !']);
    disp(['...restarting current iteration !']);
    error_m=1;
    class_st='';
    return;
end;

for i=1:size(out)
    if (isempty(out{i})==1)
        for ii=1:packages(i,3);
            class_st(:,zz)=[-1 -1 -1 -1 -1];
            zz=zz+1;
            lost=lost+1;
            disp('warning: Package lost');
        end;
        continue;
    end;
    tmp_st=out{i};
    for ii=1:packages(i,3);
        class_st(:,zz)=tmp_st(:,ii);
        zz=zz+1;
    end;
end;

if (lost > max_lost_packages)
    error_m=1;
    disp(['ERROR: Maximum number of lost packages reached !']);
end;



function num=get_class_numbers(class_st,num_of_classes)

num=zeros(num_of_classes,1);

for i=1:size(class_st,2)
        ref_nr=class_st(1,i);
        num(ref_nr)=num(ref_nr)+1;
end;



