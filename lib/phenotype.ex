defmodule Phenotype do
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		
		GenServer.cast(self(),{:init, opts.filename})
		{:ok, Map.put(opts, :ets, ets) }
	end

	def init_cortex(pid, cortex_pid, id) do 
		GenServer.cast(pid, {:init_cortex, cortex_pid, id})
	end

	def handle_cast({:init, id}, state) do 
		Phenotype.Supervisor.start_link(self(), id)
		{:noreply, state}
	end

	def handle_cast({:init_cortex, cortex_pid, id}, state) do 
		asup = Process.whereis(String.to_atom("Elixir.Phenotype.Actuator.Supervisor_#{id}"))
		ssup = Process.whereis(String.to_atom("Elixir.Phenotype.Sensor.Supervisor_#{id}"))
		nsup = Process.whereis(String.to_atom("Elixir.Phenotype.Neuron.Supervisor_#{id}"))
		IO.puts "Cortex fired, #{inspect asup} #{inspect ssup} #{inspect nsup}"

		# reading the json file. ensuring that everything is in place :)
		# dont know why he needs ets to do the job.

		json = File.read!(state.filename)

		cortex = json.cortex
		neurons = json.neurons
		actuators = json.actuators
		sensors = json.sensors

		neurons_pids = init_neurons(neurons, cortex_pid, nsup, %{})
		actuators_pids = init_actuators(actuators, cortex_pid, asup, %{})
		sensors_pids = init_sensors(sensors, cortex_pid, ssup, %{})

		Phenotype.Cortex.update(cortex_pid, cortex, Map.values(sensors_pids), Map.values(neurons_pids), Map.values(actuators_pids))

		refs = Map.merge(Map.merge(neurons_pids, actuators_pids), sensors_pids)

		bind_neurons(neurons, refs)
		bind_actuators(actuators, refs)
		bind_sensors(sensors, refs)

		{:noreply, state}
	end

	# Initialize all processes. 
	defp init_neurons([neuron|rest], cortex_pid, nsup, acc ) do
		{:ok, pid} = Phenotype.Neuron.Supervisor.start_child(nsup, [neuron, cortex_pid])
		id = "#{neuron.id.id}"
		init_neurons(rest, cortex_pid, nsup, Map.put(acc, id, pid))
	end

	defp init_neurons([], _cortex_pid, _nsup, acc) do 
		acc
	end

	defp init_actuators([actuator|rest], cortex_pid, asup, acc ) do
		{:ok, pid} = Phenotype.Actuator.Supervisor.start_child(asup, [actuator, cortex_pid])
		id = "#{actuator.id.id}"
		init_neurons(rest, cortex_pid, asup, Map.put(acc, id, pid))
	end

	defp init_actuators([], _cortex_pid, _asup, acc) do 
		acc
	end

	defp init_sensors([sensor|rest], cortex_pid, ssup, acc ) do
		{:ok, pid} = Phenotype.Sensor.Supervisor.start_child(ssup, [sensor, cortex_pid])
		id = sensor.id.id
		init_neurons(rest, cortex_pid, ssup, Map.put(acc, id, pid))
	end

	defp init_sensors([], _cortex_pid, _ssup, acc) do 
		acc
	end

	# Make the binding
	defp bind_neurons([neuron|rest], refs) do
		inputs = for input <- neuron.input_ids, do: {refs[input.id], input.weight}
		outputs = for output <- neuron.output_ids, do: refs[output.id]
		Phenotype.Neuron.update(refs[neuron.id.id], inputs, outputs)
		bind_neurons(rest, refs)
	end

	defp bind_neurons([], _refs) do 
	end

	defp bind_actuators([actuator|rest], refs) do
		outputs = Map.take(refs, actuator.fanin_ids)
		Phenotype.Actuator.update(refs[actuator.id.id], outputs)		
		bind_actuators(rest, refs)
	end

	defp bind_actuators([], _refs) do 
	end

	defp bind_sensors([sensor|rest], refs) do
		inputs = Map.take(refs, sensor.fanout_ids)
		Phenotype.Sensor.update(refs[sensor.id.id],inputs)			
		bind_sensors(rest, refs)
	end

	defp bind_sensors([], _refs) do 
	end
end