function deleteHandles(handles)
    for n=1:numel(handles)
        h = handles(n);
        if ~isempty(h) && isvalid(h)
            delete(h);
        end
    end
end