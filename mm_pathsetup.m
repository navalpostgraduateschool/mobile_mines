function mPathname = mm_pathsetup(mPathname)
    if(nargin<1 || ~isdir(mPathname))
        mPathname = fileparts(mfilename('fullpath'));
    end
    
    if(~isdeployed)
        addpath(mPathname);
        subPaths = {'classes','app','tests'};
        
        for s=1:numel(subPaths)
            addpath(genpath(fullfile(mPathname,subPaths{s})));
        end        
    end
end