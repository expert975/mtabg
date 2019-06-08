outputChatBox("Welcome to my development server! I might be doing some\
strange experiment that breaks the game, so stick around if you want\
to test or ask to play later")

local inMatch = false
local inLobby = false

function Player:disableHudComponents(...)
	for _, component in ipairs(arg) do
		setPlayerHudComponentVisible(component, false)
	end
end

function Player:enableHudComponents(...)
	for _, component in ipairs(arg) do
		setPlayerHudComponentVisible(component, true)
	end
end

function Player:getInMatch()
	return inMatch
end

function Player.setInMatch(_inMatch)
	inMatch = _inMatch
end
addEvent("onSetInMatch", true)
addEventHandler("onSetInMatch", localPlayer, Player.setInMatch)

function Player:getInLobby()
	return inLobby
end

function Player.setInLobby(_inLobby)
	inLobby = _inLobby
end
addEvent("onSetInLobby", true)
addEventHandler("onSetInLobby", localPlayer, Player.setInLobby)

local function delegatePlayerDamage(attacker, weapon, bodypart, loss)
	cancelEvent()
	triggerServerEvent("onDamagePlayer", resourceRoot,
	                   attacker, weapon, bodypart, loss)
end
addEventHandler("onClientPlayerDamage", localPlayer, delegatePlayerDamage)

local lastThrownGrenade
local grenadeTime = 0
local damageAtDistance = {}
local grenadeCounter = 1
local distance = 0
function treatProjectileCreation(creator)
	if creator == localPlayer
	and source:getType() == 16 then --Only for grenades
		lastThrownGrenade = source
		triggerServerEvent("onPlayerWeaponThrow", resourceRoot)
		local p = creator:getPosition()
		local r = creator:getRotation()
		source:setCounter(30000)
		-- local grenadePos =
		-- 	Vector3(getPointInFrontOfPoint(p.x, p.y, p.z, r.z, distance))
		-- source:setPosition(grenadePos)
		source:setVelocity(.4, .1, .1)
		-- source:setAngularVelocity(0, 0, 0)
		-- source:setFrozen(true)
		-- creator:setFrozen(true)

		damageAtDistance[grenadeCounter] =
			{["distance"] = distance, ["damage"] = 0}
		grenadeCounter = grenadeCounter + 1
		distance = distance + .1
	end
end
addEventHandler("onClientProjectileCreation", root, treatProjectileCreation)

local graphMax = 90
local graphX, graphY = 500, graphMax*8

-- x1 = 4.8
-- y1 = 75.786858

-- x2 = 8.5
-- y2 = 8.4916954

-- m = -18.187881783783

-- y = mx + b
--    damage = 52.227467
--    distance = 6.1
-- 52.227467 = 6.1*-18.187881783783 + b
-- -b = 6.1*-18.187881783783 - 52.227467
-- b = 163.173545881
-- damage = x*-18.187881783783 + 163.173545881


-- damage = x*-18.187881783783 + 163.173545881

-- teta = -86.853

-- catAdj = 4.5
-- (cos teta) * catAdj = hip

local function calculateGrenadeDamage(distance)
	if distance <= 4.5 then
		return 82.5
	elseif distance >= 9 then
		return 0
	else
		return distance*-18.187881783783 + 163.173545881
	end
end

for dist = 0.05, 10, 0.1 do
	table.insert(damageAtDistance,
	             {["damage"] = calculateGrenadeDamage(dist),
		          ["distance"] = dist})
	grenadeCounter = grenadeCounter + 1
end
iprint(grenadeCounter)
iprint(table.maxn(damageAtDistance))

local function normalizeAngle(angle)
	if angle < 0 then
		angle = mapValues(angle, -90, 0, 270, 360)
	end
	return angle
end

local function getCameraRotationZ()
	local cx, cy, _, px, py = getCameraMatrix(localPlayer)
	local camRot = math.deg(math.atan2(cy - py, cx - px) + math.pi/2)
	return normalizeAngle(camRot)
end

local arrow = DxTexture("lootPointEditor/arrow.png")

local grenades = {}
local function plot()
	-- for i in pairs(damageAtDistance) do
	-- 	if i > 101 then
	-- 		dxDrawCircle(damageAtDistance[i].distance*8*10,
	-- 		             graphY - damageAtDistance[i].damage*8, 2, 0,
	-- 		             0xFFFF00FF, 0xFFFF00FF)
	-- 	else
	-- 		dxDrawCircle(damageAtDistance[i].distance*8*10,
	-- 		             graphY - damageAtDistance[i].damage*8, 2, 0,
	-- 		             0xFF00FFFF, 0xFF00FFFF)
	-- 	end
	-- end
	local targetCounter = 0
	for i, projectile in
	ipairs(Element.getAllByType("vehicle", root, false)) do
		-- if projectile:getType() == 16 then
			-- dxDrawText(tostring(projectile:getCounter()), 200, 100 + 20*i)
			local projPos = projectile:getPosition()
			local playerPos = localPlayer:getPosition()
			local dist = projPos - playerPos
			dxDrawText(tostring(Vector3.getLength(dist)), 10, 100 + 20*i)
			local angle = normalizeAngle(math.deg(math.atan2(dist.y, dist.x)))
			dxDrawText(angle, 260, 100 + 20*i)
			dxDrawImage(700 + 30*targetCounter, 350, 32, 32, arrow,
			            getCameraRotationZ() - angle)
			dxDrawImage(700 + 30*targetCounter, 400, 32, 32, arrow, -angle)
		-- end
			targetCounter = targetCounter + 1
	end
	dxDrawText("Camera angle: " ..getCameraRotationZ(), 450, 50)
	dxDrawText("Player angle: " ..localPlayer:getRotation().z, 450, 70)
	-- localPlayer:setRotation(0, 0, getCameraRotationZ())
	if targetCounter > 0 then
		dxDrawText("Distance", 10, 100)
		dxDrawText("Angle", 260, 100)
		dxDrawText("Target direction ", 610, 360)
		dxDrawText("Target angle ", 610, 410)
		dxDrawText("Camera angle ", 610, 460)
		dxDrawImage(700, 450, 32, 32, arrow, getCameraRotationZ())
	end
end
addEventHandler("onClientRender", root, plot)

local function insertDamage(grenadeID, damage)
	iprint(tostring(grenadeID), tostring(damage))
	damageAtDistance[grenadeID]["damage"] = damage
end
addEvent("notifyGrenadeDamage", true)
addEventHandler("notifyGrenadeDamage", localPlayer, insertDamage)

local function dumpDamage()
	local file = File.new("grenadeDamage.lua")
	file:write(inspect(damageAtDistance))
	file:close()
end
addCommandHandler("dumpDamage", dumpDamage)
