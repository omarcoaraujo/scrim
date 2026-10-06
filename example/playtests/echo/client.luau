--// Services
const Players = game:GetService "Players"

--// Functions
const function echo(value: any): any
	return value
end

const function explode()
	error "boom"
end

const function position()
	return Players.LocalPlayer.Character.PrimaryPart.Position
end

--// End
return {
	echo = echo,
	explode = explode,
	position = position,
}
