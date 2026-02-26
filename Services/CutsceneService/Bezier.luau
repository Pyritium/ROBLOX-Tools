local module = {}

local function BezierCurve(Points, Alpha)
	local TPTS = Points;
	while #TPTS > 1 do
		local NPTS = {};
		for i = 1, #TPTS - 1 do
			NPTS[i] = TPTS[i]:Lerp(TPTS[i + 1], Alpha);
		end
		TPTS = NPTS;
	end
	--print(Alpha);
	return TPTS[1];
end

function module:Bezier(Points, Alpha)
	return BezierCurve(Points, Alpha);
end

function module:Polynomial(Points)
	return 0;
end

return module
