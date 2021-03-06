-- Farm Structure Framework build script
-- by viveleroi

local index = 1
turtle.select(index)
args = {...}

function place()
  turtle.digDown()
  turtle.placeDown()
  if turtle.getItemCount(index) == 0 then
    index = index + 1
  end
  if index > 16 then
      index = 1
  end
  turtle.select(index)
end

function buildLayer(length)
  place()
  side = length
  -- sides of square
  for i = 1, 4 do
    for j = 1, side-1 do
      while turtle.detect() do
        turtle.dig()
      end
      turtle.forward()
      place()
    end
    turtle.turnRight()
  end
end

-- detect current script filename
function myName()
  fullName = shell.getRunningProgram()
  return fs.getName(fullName)
end

if #args < 1 then
  print("Usage:")
  print(" "..myName().." <length>")
  print(" Place enough materials in the turtle inv")
  return
end

if tonumber(args[1])==nil then
    print("Dimensions must be a number")
    return
end

if turtle.refuel(0) then
  turtle.refuel(32)
else
  print("First slot must contain fuel")
end

buildLayer(tonumber(args[1]))