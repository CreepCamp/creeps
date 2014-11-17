defmodule Phenotype.Supervisor do 
	use Supervisor

	def start_link(pid, id) do 
		Supervisor.start_link(__MODULE__, [pid, id], [name: String.to_atom("#{__MODULE__}_#{id}")])
	end

	def init([pid, id]) do
		IO.puts "Initialized #{__MODULE__}"
		
		children = [
			supervisor(Phenotype.Actuator.Supervisor, [id], restart: :transient),
			supervisor(Phenotype.Sensor.Supervisor, [id], restart: :transient),
			supervisor(Phenotype.Neuron.Supervisor, [id], restart: :transient),
			worker(Phenotype.Cortex, [pid, id], restart: :transient)
		]

		supervise(children, strategy: :one_for_one)
	end
end