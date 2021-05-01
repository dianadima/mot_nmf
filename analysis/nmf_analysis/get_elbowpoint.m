function [max_dist,elbow_idx] = get_elbowpoint(curve,doplot)
% solution from Stack Overflow: https://stackoverflow.com/questions/2018178/finding-the-best-trade-off-point-on-a-curve
% note that this solution has some limitations, e.g. dependence on number
% of points, but works reasonabluy well

np = numel(curve);
coord = [1:np; curve]';              

% get vector between first and last point - this is the line
line_vec = coord(end,:) - coord(1,:);

% normalize the line vector
line_vec = line_vec / sqrt(sum(line_vec.^2));

% vector between all points and first point
vec_first = bsxfun(@minus, coord, coord(1,:));

% Split vector into a parallel and perpendicular component to the line
%       - project vec_first onto line to get parallel component
%               - take scalar product of the vector with the unit vector that
%                 points in the direction of the line (= length)
%               - multiply the scalar product by vector to get the parallel comp
%      - subtract first_vec from the parallel one to get perpendicular vector
% Take the norm of the perpendicular component to get the distance

scalar_product = dot(vec_first, repmat(line_vec,np,1), 2);
vec_first_parallel = scalar_product * line_vec;
vec_to_line = vec_first - vec_first_parallel;

% distance to line is the norm of vecToLine
dist_to_line = sqrt(sum(vec_to_line.^2,2));

% plot the distance to line
if doplot
    figure('Name','distance from curve to line'), plot(dist_to_line)
end

% now find the maximum = elbow point
[max_dist,elbow_idx] = max(dist_to_line);

% plot if requested
if doplot
    figure, plot(curve,'k','LineWidth',2)
    hold on
    plot(coord(elbow_idx,1), coord(elbow_idx,2), 'or','LineWidth',2)
    box off
    set(gca,'FontSize',18)
    set(gca,'xgrid','on')
end

end

