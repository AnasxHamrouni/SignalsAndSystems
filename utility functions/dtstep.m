## Copyright (C) 2026 Anas Hamrouni
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {} {@var{retval} =} dtstep (@var{input1}, @var{input2})
##
## @seealso{}
## @end deftypefn

## Author: Anas Hamrouni <anashamrouni@Anass-MacBook-Pro.local>
## Created: 2026-01-26

function [x, n] = dtstep (n0, n1, n2)
% dtstep: returns discrete-time unit step function
% [x, n] = dtstep(n0,n1,n2)
% produces x[n] = u[n - n0] for n1 <= n <= n2
n = n1:n2;
x = zeros(1,length(n));
x(n>=n0) = 1;
endfunction
