
--return { disabled = true }

local medium = {
        0,0,0,0,9,2,1,8,0,
        0,8,0,0,0,0,0,2,4,
        0,0,4,0,1,0,5,0,0,
        0,0,0,0,3,8,0,0,0,
        0,0,0,2,0,9,0,1,0,
        2,0,0,0,0,0,0,0,6,
        0,0,0,0,8,4,6,0,0,
        0,9,0,3,6,5,8,4,0,
        0,0,0,0,0,0,0,0,0,
}

print("# fields:", #medium)
print("middle:", medium[41], "surrounded by", medium[40], medium[42])
