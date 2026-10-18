--!nocheck
-- Release version: a plain major.minor.patch string.

return function(t)
	local Version = t.config("Version")

	t.describe("Version", function()
		t.it("is semver major.minor.patch", function()
			t.truthy(type(Version.VERSION) == "string" and string.match(Version.VERSION, "^%d+%.%d+%.%d+$") ~= nil, Version.VERSION)
		end)
	end)
end
