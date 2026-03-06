classdef Logger < handle
    properties(SetAccess = protected)
        shouldLogToFile logical = false;
        logFilename char = 'se_mobile_mines_log.txt'
    end

    properties (Access = private)
        TextHandle = []        
    end

    methods (Access = private)
        function this = Logger
            % Private constructor (prevents external instantiation)
        end
    end

    methods (Static)
        function obj = getInstance()
            persistent localInstance
            if isempty(localInstance) || ~isvalid(localInstance)
                localInstance = Logger();
            end
            obj = localInstance;
        end
    end

    methods

        function setTextHandle(this, h)
            if isempty(h) || isvalid(h)
                this.TextHandle = h;
            end
        end

        function setLogToFile(this, shouldIt)
            if nargin>1                 
                this.shouldLogToFile = ~isempty(shouldIt) && shouldIt;
            end
        end

        function log(this, level, message, varargin)
            if numel(varargin) > 0
                message = sprintf(message, varargin{:});
            end

            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            fullMsg = sprintf('[%s] [%s] %s', timestamp, level, message);

            if ~isempty(this.TextHandle) && isvalid(this.TextHandle)
                previous = get(this.TextHandle,'value');
                if isempty(previous)
                    setText = fullMsg;
                elseif ischar(previous)
                    setText = {fullMsg; previous};
                else
                    setText = [{fullMsg}; previous];
                end
                set(this.TextHandle,'value',setText);
                drawnow;
            else
                fprintf(1,'%s\n',fullMsg);
            end

            if this.shouldLogToFile
                fid = fopen(this.logFilename,'at');
                if fid ~= -1
                    fprintf(fid,'%s\n',fullMsg);
                    fclose(fid);
                end
            end
        end
    end
end