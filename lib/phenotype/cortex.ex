defmodule Phenotype.Cortex do 
	defstruct id: nil, sensor_pids: [], actuator_pids: [], neuron_pids: [], phenotype_pid: nil
	use GenServer

	def start_link(phenotype_pid, id) do 
		GenServer.start_link(__MODULE__, [phenotype_pid, id], [name: String.to_atom("#{__MODULE__}_#{id}")])
	end

	def init([phenotype_pid, id] = opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		
		Phenotype.init_cortex(phenotype_pid, self(), id)
		{:ok, %Phenotype.Cortex{phenotype_pid: phenotype_pid}}
	end	

	def update(pid, cortex, sensor_pids, neuron_pids ,actuator_pids) do 
		GenServer.cast(pid, {:update, cortex,sensor_pids, neuron_pids ,actuator_pids})
	end

	def handle_cast({:update, cortex, sensor_pids, neuron_pids, actuator_pids}, state) do
		{:noreply, %Phenotype.Cortex{state| id: cortex.id.id, sensor_pids: sensor_pids, neuron_pids: neuron_pids, actuator_pids: actuator_pids}}
	end
end