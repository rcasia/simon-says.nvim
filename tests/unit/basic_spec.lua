pcall(require, "luacov")

describe("simon-says", function()
	it("loads without error", function()
		local ok = pcall(require, "simon-says")
		assert.is_true(ok)
	end)
end)
