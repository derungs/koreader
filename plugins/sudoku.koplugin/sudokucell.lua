local SudokuCell = {
    fixed = nil,
    number = nil,
    numbers = nil
}

function SudokuCell:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SudokuCell:add(n)
    if not self.fixed then
        self.numbers = self.numbers or {}
        self.numbers[n] = n
        self.number = nil
    end
end

function SudokuCell:remove(n)
    if not self.fixed and self.numbers then
        self.numbers[n] = nil
    end
end

function SudokuCell:toggle(n)
    if not self.fixed then
        self.numbers = self.numbers or {}
        if self.numbers[n] then
            self.numbers[n] = nil
        else
            self.numbers[n] = n
        end
        self.number = nil
    end
end

function SudokuCell:set(n)
    if not self.fixed then
        self.number = n
        self.numbers = nil
    end
end

function SudokuCell:clear()
    if not self.fixed then
        self.number = nil
        self.numbers = nil
    end
end

return SudokuCell