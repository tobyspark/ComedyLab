function out = isinfront(point, origin, vec)

% Calculates a csv file with analytic data
% created 1.2.2014
% @author Chris Frauenberger
%
%
% Input: point the point to test 
%        origin of the plane
%        vector (line of sight) from origin
%
% Output: true (1) if point is in front of origin looking along vec
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if (point-origin)*vec' > 0 
    out = 1;
else
    out = 0;
end
