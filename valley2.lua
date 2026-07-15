local today = os.date("*t")

local daystill = 22 - today.day

if not today.month == 6 and not today.day == 22 then
    print("Wait" .. daystill .. " days.")
end
