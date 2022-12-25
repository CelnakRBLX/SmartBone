local MetricUnit = 0.2800336040324839
local ImperialUnit = 0.9187454494539344

local Unit = {
	Conversions = {
		--Metric
		Kilometer = MetricUnit * 1000,
		Hektometer = MetricUnit * 100,
		Decameter = MetricUnit * 10,
		Meter = MetricUnit,
		Decimeter = MetricUnit / 10,
		Centimeter = MetricUnit / 100,
		Millimeter = MetricUnit / 1000,
		--Imperial
		Miles = ImperialUnit * 5280,
		Yards = ImperialUnit * 3,
		Feet = ImperialUnit,
		Inches = ImperialUnit / 12,
	},
}

function Unit.Convert(Value: number, Method: string)
	return Unit.Conversions[Method] ~= nil and Value * Unit.Conversions[Method]
end

function Unit.ConvertInverse(Value: number, Method: string)
	return Unit.Conversions[Method] ~= nil and Unit.Conversions[Method] / Value
end

function Unit.ConvertRounded(Value: number, Method: string)
	return Unit.Conversions[Method] ~= nil and math.floor(Value * Unit.Conversions[Method])
end

return Unit
