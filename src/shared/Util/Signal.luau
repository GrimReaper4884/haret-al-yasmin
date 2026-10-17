--!strict
-- Minimal synchronous signal (no BindableEvent, so arguments are passed by reference).

export type Connection = { Disconnect: (Connection) -> () }
export type Signal<T...> = {
	Connect: (Signal<T...>, (T...) -> ()) -> Connection,
	Fire: (Signal<T...>, T...) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local handlers: { [number]: (T...) -> () } = {}
	local nextId = 0
	local self = {} :: any

	function self.Connect(_, fn: (T...) -> ()): Connection
		nextId += 1
		local id = nextId
		handlers[id] = fn
		local conn = {} :: any
		function conn.Disconnect()
			handlers[id] = nil
		end
		return conn
	end

	function self.Fire(_, ...: T...)
		for _, fn in handlers do
			task.spawn(fn, ...)
		end
	end

	return self
end

return Signal
