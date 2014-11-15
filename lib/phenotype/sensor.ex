defmodule Phenotype.Sensor do 
	defstruct id: nil, cortex_pid: nil, name: nil, vector_length: 0, fanout_pids: []
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init([sensor, cortex_pid]) do 
		IO.puts "Initilizing #{__MODULE__}"
		state = %Phenotype.Sensor{id: sensor.id.id, cortex_pid: cortex_pid, name: sensor.name, vector_length: sensor.vector_length}
		{:ok, state}
	end

	def update(pid, fanouts) do 
		GenServer.cast(pid, {:update, fanouts})
	end

	def handle_cast({:update, fanouts}, state) do 
		{:noreply, %Phenotype.Sensor{state|fanout_pids: fanouts}}
	end
end
