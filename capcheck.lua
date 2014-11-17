-- Reactor/Capacitor Management ComputerCraft script
-- by viveleroi 2014
-- Automatically checks for wired attachements for EnderIO capacitor bank, monitor, big reactor
-- Will automatically active reactor when capacitor bank too low, or deactive when too high
-- Connected devices take priority over modem devices
-- Requires 1x3 monitors

-- based on code: http://pastebin.com/rjfa4ymR

local version = 0.1

print("Reactor/Capacitor Manager v"..version)
 
local upper = 0.90 --Upper limit for computer to stop transmitting redstone signal. 0.90=90% full.
local lower = 0.10 --Lower limit for computer to start transmitting redstone signal.
 
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
reactor = "none"
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
 
-- detect reactor
reactorFace=detectDevice("BigReactors-Reactor")
if reactorFace~="none" then
  reactor=peripheral.wrap(reactorFace)
  print ("Reactor on the " .. reactorFace .. " connected.")
else
  for Index = 1, #peripheralList do
    if string.find(peripheralList[Index], "Reactor") then
      reactor=peripheral.wrap(peripheralList[Index])
      print ("Reactor on wired modem: "..peripheralList[Index].." connected.")
    end
  end
  if reactor == "none" then
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
    print ("Warning - No Monitor attached, continuing without.")
  end
end

-- default to no redstone signal
redstone.setOutput("back", false)
 
--If monitor is attached, write data on monitor
if monitor ~= "none" then
  monitor.clear()
  monitor.setBackgroundColour((colours.grey))
  monitor.setCursorPos(1,4)
  monitor.write(" ON ")
  monitor.setBackgroundColour((colours.red))
  monitor.setCursorPos(5,4)
  monitor.write(" OFF ")
  monitor.setBackgroundColour((colours.black))
end

eLast = 0;
 
while true do

  -- check energy
  eNow = cell.getEnergyStored("unknown")
  eMax = cell.getMaxEnergyStored("unknown")
  fill = (eNow / eMax)
  perc = math.floor(fill*100)
  diff = eNow - eLast
  eLast = eNow;
 
  if monitor ~= "none" then

    if eMax >= 10000000 then
      monitor.setCursorPos(11,1)
      monitor.write("Storage:")
      monitor.setCursorPos(11,2)
      monitor.setBackgroundColour((colours.blue))
      monitor.write(math.ceil(eNow/1000).."kRF")
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(11,3)
      monitor.write("Capacity:")
      monitor.setCursorPos(11,4)
      monitor.setBackgroundColour((colours.blue))
      monitor.write(math.ceil(eMax/1000).."kRF")
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(21,1)
      monitor.write("Fill:")
      monitor.setCursorPos(21,2)
      monitor.setBackgroundColour((colours.cyan))
      monitor.write(perc.."%")
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(21,4)
      monitor.write("Change:")
      monitor.setCursorPos(21,5)
      monitor.clearLine()
      monitor.setBackgroundColour((colours.cyan))
      monitor.write(math.ceil(diff/1000).."k/s")
      monitor.setBackgroundColour((colours.black))
    else   
      monitor.setCursorPos(11,1)
      monitor.write("Storage:")
      monitor.setCursorPos(11,2)
      monitor.setBackgroundColour((colours.blue))
      monitor.write(math.ceil(eNow))
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(11,3)
      monitor.write("Capacity:")
      monitor.setCursorPos(11,4)
      monitor.setBackgroundColour((colours.blue))
      monitor.write(math.ceil(eMax))
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(21,1)
      monitor.write("Fill:")
      monitor.setCursorPos(21,2)
      monitor.setBackgroundColour((colours.cyan))
      monitor.write(perc.."%")
      monitor.setBackgroundColour((colours.black))
      monitor.setCursorPos(21,4)
      monitor.write("Change:")
      monitor.setCursorPos(21,5)
      monitor.clearLine()
      monitor.setBackgroundColour((colours.cyan))
      monitor.write(math.ceil(diff))
      monitor.setBackgroundColour((colours.black))
    end
    monitor.setCursorPos(1,2)
    monitor.write("Reactors:")
  end
   
  if fill > upper then
    redstone.setOutput("back", false)
    reactor.setActive(false)
    print("Deactivating reactors...")
   
    if monitor ~= "none" then
      monitor.setBackgroundColour((colours.grey))
      monitor.setCursorPos(1,4)
      monitor.write(" ON ")
      monitor.setBackgroundColour((colours.red))
      monitor.setCursorPos(5,4)
      monitor.write(" OFF ")
      monitor.setBackgroundColour((colours.black))
    end
  elseif fill < lower then

    redstone.setOutput("back", true)
    reactor.setActive(true)
    print("Activating reactors...")
   
    if monitor ~= "none" then
      monitor.setBackgroundColour((colours.green))
      monitor.setCursorPos(1,4)
      monitor.write(" ON ")
      monitor.setBackgroundColour((colours.grey))
      monitor.setCursorPos(5,4)
      monitor.write(" OFF ")
      monitor.setBackgroundColour((colours.black))
    end
  end
    
  sleep(1)

end