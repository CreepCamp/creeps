defmodule Phenotype.Actuator do 
	defstruct id: nil, cortex_id: nil, name: nil, vector_length: 0, fanin_ids: []
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		{:ok, opts}
	end
end