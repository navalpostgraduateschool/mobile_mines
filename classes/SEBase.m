classdef SEBase < handle
    % SEBase
    % Infrastructure base class providing:
    %   - Standardized logging via Logger singleton
    %   - Enforced verify() contract

    properties (Access = protected)
        verbose (1,1) logical = true
    end

    methods

        function [pass, details] = verify(this)
            % Default verify enforces override requirement

            msg = sprintf('verify() not implemented in class %s.', class(this));

            if nargout == 0
                fprintf('Verification FAILED: %s\n', msg);
                error('SEBase:VerifyNotImplemented', msg);
            else
                pass = false;

                details = struct();
                details.className = class(this);
                details.timestamp = datestr(now);
                details.pass = pass;
                details.summary = msg;
                details.metrics = struct();  % metrics allows each subclass to include domain-specific outputs
                details.notes = '';

                error('SEBase:VerifyNotImplemented', msg);

            end
        end

        function setVerbose(this, tf)
            this.verbose = logical(tf);
        end

        function logStatus(~, message, varargin)
            Logger.getInstance().log('STATUS', message, varargin{:});
        end

        function logWarning(~, message, varargin)
            Logger.getInstance().log('WARNING', message, varargin{:});
        end

        function logError(~, message, varargin)
            Logger.getInstance().log('ERROR', message, varargin{:});
        end        
    end
end