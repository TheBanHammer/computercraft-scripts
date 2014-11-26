-- Reactor/Capacitor Management ComputerCraft script
-- by viveleroi 2014
-- Automatically checks for wired attachements for EnderIO capacitor bank, monitor, big reactor
-- Will automatically active reactor when capacitor bank too low, or deactive when too high
-- Connected devices take priority over modem devices
-- Requires 3x3 monitors (2x3 if less than 4 reactors)

-- based on code: http://pastebin.com/rjfa4ymR

local version = 0.2

print("Reactor/Capacitor Manager v"..version)

local file = fs.open("startup", "w")
file.write("shell.run(\"capcheck\")")
file.close()
 
local upper = 0.95 --Upper limit for computer to stop transmitting redstone signal. 0.90=90% full.
local lower = 0.20 --Lower limit for computer to start transmitting redstone signal.
 
function round2(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

--Device detection
isError=0
 
function detectDevice(DeviceName)
  deviceFace="none"
  for k,v in pairs(redstone.getSides()) do
   if peripheral.getType(v)==DeviceName then
     deviceFace = v
     break
   end
  end
  return(deviceFace)
end
 
cell = "none"
monitor = "none"
local peripheralList = peripheral.getNames()
 
-- detect energy storage cell
capacitorFace=detectDevice("cofh_thermalexpansion_energycell")
if capacitorFace~="none" then
   cell=peripheral.wrap(capacitorFace)
   print ("TE Energy cell on the " .. capacitorFace .. " connected.")
else
  capacitorFace=detectDevice("tile_enderio_blockcapacitorbank_name")
  if capacitorFace~="none" then
    cell=peripheral.wrap(capacitorFace)
    print ("EnderIO capacitorbank on the " .. capacitorFace .. " connected.")
  else
    for Index = 1, #peripheralList do
      if string.find(peripheralList[Index], "cofh_thermalexpansion_energycell") then
        cell=peripheral.wrap(peripheralList[Index])
        print ("TE Energy cell on wired modem: "..peripheralList[Index].." connected.")
      elseif string.find(peripheralList[Index], "tile_enderio_blockcapacitorbank_name") then
        cell=peripheral.wrap(peripheralList[Index])
        print ("EnderIO capacitorbank on wired modem: "..peripheralList[Index].." connected.")
      end
    end
    if cell == "none" then
      print("No Energy storage found. Halting script!")
      return
    end
  end
end
 
-- detect reactors
reactors = {}
reactorFace=detectDevice("BigReactors-Reactor")
if reactorFace~="none" then
  table.insert(reactors,peripheral.wrap(reactorFace))
  print ("Reactor on the " .. reactorFace .. " connected.")
else
  for Index = 1, #peripheralList do
    if string.find(peripheralList[Index], "Reactor") then
      table.insert(reactors,peripheral.wrap(peripheralList[Index]))
      print ("Reactor on wired modem: "..peripheralList[Index].." connected.")
    end
  end
  if table.getn(reactors) == 0 then
    print("No reactors found. Halting script!")
    return
  end
end

-- detect monitor
MonitorSide=detectDevice("monitor")
if MonitorSide~="none" then
  monitor=peripheral.wrap(MonitorSide)
  print ("Monitor on the " .. MonitorSide .. " connected.")
else
  for Index = 1, #peripheralList do
    if string.find(peripheralList[Index], "monitor") then
      monitor=peripheral.wrap(peripheralList[Index])
      print ("Monitor on wired modem: "..peripheralList[Index].." connected.")
    end
  end
  if monitor == "none" then
    print("No monitor found. Halting script!")
    return
  end
end

-- default to no redstone signal
redstone.setOutput("back", false)

function setReactorState( state )
  for i, reactor in ipairs(reactors) do
    reactor.setActive(state)
  end
end

-- turn all reactors off
setReactorState(false)
 
-- --If monitor is attached, write data on monitor
monitor.clear()

monitor.setCursorPos(1,6)
monitor.write("Reactors")

monitor.setCursorPos(10,8)
monitor.write("Buff")

monitor.setCursorPos(16,8)
monitor.write("Temp")

monitor.setCursorPos(22,8)
monitor.write("Output")

eLast = 0;
 
while true do

  -- check energy
  eNow = cell.getEnergyStored("unknown")
  eMax = cell.getMaxEnergyStored("unknown")
  fill = (eNow / eMax)
  perc = fill*100
  diff = eNow - eLast
  eLast = eNow;
 
  displayStorage = math.ceil(eNow)
  displayCapacity = math.ceil(eMax)
  displayFill = round2(perc,2).."%"
  displayChange = round2(diff,2)

  -- over a billion
  if eMax >= 1000000000 then
    displayCapacity = math.ceil(eMax/1000000000).."bRF"
  end

  -- over a million
  if eMax >= 1000000 then
    displayStorage = math.ceil(eNow/1000).."kRF"
    displayCapacity = math.ceil(eMax/1000).."kRF"
    displayChange = round2(diff/1000,2).."k"
  end

  monitor.setCursorPos(1,1)
  monitor.write("Storage:")
  monitor.setCursorPos(1,2)
  monitor.clearLine()
  monitor.setBackgroundColour((colours.blue))
  monitor.write(displayStorage)
  monitor.setBackgroundColour((colours.black))
  monitor.setCursorPos(1,3)
  monitor.write("Capacity:")
  monitor.setCursorPos(1,4)
  monitor.clearLine()
  monitor.setBackgroundColour((colours.blue))
  monitor.write(displayCapacity)
  monitor.setBackgroundColour((colours.black))
  monitor.setCursorPos(16,1)
  monitor.write("Fill:")
  monitor.setCursorPos(16,2)
  monitor.setBackgroundColour((colours.cyan))
  monitor.write(displayFill)
  monitor.setBackgroundColour((colours.black))
  monitor.setCursorPos(16,3)
  monitor.write("Change:")
  monitor.setCursorPos(16,4)
  monitor.setBackgroundColour((colours.cyan))
  monitor.write(displayChange)
  monitor.setBackgroundColour((colours.black))
   
  if fill > upper then
    redstone.setOutput("back", false)
    setReactorState(false)
  elseif fill < lower then
    redstone.setOutput("back", true)
    setReactorState(true)
  end

  cursorY = 9

  -- reactor status
  for i, reactor in ipairs(reactors) do
    monitor.setCursorPos(1,cursorY)
    monitor.clearLine()
    monitor.write(i..":")
    monitor.setCursorPos(4,cursorY)

    if reactor.getActive() then
      monitor.setBackgroundColour((colours.green))
      monitor.write(" ON ")
      monitor.setBackgroundColour((colours.black))
    else
      monitor.setBackgroundColour((colours.red))
      monitor.write(" OFF ")
      monitor.setBackgroundColour((colours.black))
    end

    -- internal buffer
    displayEnergyBuffer = math.floor((reactor.getEnergyStored()/10000000)*100).."%"
    monitor.setCursorPos(10,cursorY)
    monitor.write(displayEnergyBuffer)

    -- temp
    displayTemperature = math.ceil(reactor.getCasingTemperature()).."c"
    if reactor.getCasingTemperature() > 1000 then
      displayTemperature = round2(reactor.getCasingTemperature()/1000,2).."k c"
    end

    monitor.setCursorPos(16,cursorY)
    monitor.write(displayTemperature)

    -- energy produced
    displayEnergyProduced = round2(reactor.getEnergyProducedLastTick(),2).."RF"
    if reactor.getEnergyProducedLastTick() > 1000 then
      displayEnergyProduced = round2(reactor.getEnergyProducedLastTick()/1000,2).."kRF"
    end
    monitor.setCursorPos(22,cursorY)
    monitor.write(displayEnergyProduced)

    cursorY = cursorY + 1
    
  end
    
  sleep(1)

end