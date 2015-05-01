defmodule ExoSelf do
	use GenServer

  def start(filename, callback) do 
    start_link(%{filename: filename, pid: callback})
  end

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		
    # seeding :)
    {a,b,c} = :erlang.now()
    :random.seed(a,b,c)

		GenServer.cast(self(),{:init, 1 }) 
		{:ok, Map.put(opts, :ets, nil) }
	end

	def init_cortex(pid, cortex_pid, id) do 
		GenServer.cast(pid, {:init_cortex, cortex_pid, id})
	end

  def finished(pid, neurons) do 
    GenServer.cast(pid, {:finished, neurons})
  end

	def handle_cast({:init, id}, state) do 
		Phenotype.Supervisor.start_link(self(), id)
		{:noreply, state}
	end

	def handle_cast({:init_cortex, cortex_pid, id}, state) do 
		asup = Process.whereis(String.to_atom("Elixir.Phenotype.Actuator.Supervisor_#{id}"))
		ssup = Process.whereis(String.to_atom("Elixir.Phenotype.Sensor.Supervisor_#{id}"))
		nsup = Process.whereis(String.to_atom("Elixir.Phenotype.Neuron.Supervisor_#{id}"))
    # IO.puts "Cortex fired, #{inspect asup} #{inspect ssup} #{inspect nsup}"

		# reading the json file. ensuring that everything is in place :)
		# dont know why he needs ets to do the job.
    Genotype.load(state.filename)

		[cortex] = Genotype.fetch_all(state.filename, :cortex)
		neurons = Genotype.fetch_all(state.filename, :neuron)
		actuators = Genotype.fetch_all(state.filename, :actuator)
		sensors = Genotype.fetch_all(state.filename, :sensor)

    scapes_pids = init_scapes(sensors,actuators)
		neurons_pids = init_neurons(neurons, cortex_pid, nsup, %{})
		actuators_pids = init_actuators(actuators, cortex_pid, asup, %{})
		sensors_pids = init_sensors(sensors, cortex_pid, ssup, %{})

		Phenotype.Cortex.update(cortex_pid,
        cortex,
        Map.values(sensors_pids), 
        Map.values(neurons_pids),
        Map.values(actuators_pids))

		refs = Map.merge(Map.merge(neurons_pids, actuators_pids), sensors_pids)

		bind_neurons(neurons, refs)
		bind_actuators(actuators, scapes_pids, refs)
		bind_sensors(sensors, scapes_pids, refs)

    # By the book, the cortex here should start working ...
    # As there aren't any trainer right now it should ask the cortex 
    # to do the job several hundreds of times
    Phenotype.Cortex.start(cortex_pid, 10)

		{:noreply, state}
	end


  # Note : neurons_n_weight follow this logic :
  # [{neuron_id, [{pid, weigth, id} = input] = inputs ]}
  def handle_cast({:finished, neurons_n_weight}, state ) do
    IO.puts "Yeah Cortex finished ! Hourray"

    # Now that we're finished, saves the status of the NN to file (update)
    for {id, input_weight} <- neurons_n_weight do
      {id, type, content} = Genotype.fetch(state.filename,id )
      # syntaxic sugar :)
      new_inputs = for {_pid, weight, input_id} <- input_weight, do: %{id: input_id, weight: weight}
      Genotype.insert(state.filename, id, type, %{content| input_ids: new_inputs})
    end


    send state.pid, {:finished, self()}
    {:noreply, state} 
  end


	# Initialize all processes. 
  defp init_scapes(sensors, actuators) do 
    sensor_scapes = for s <- sensors, do: s.scape
    actuator_scapes = for s <- actuators, do: s.scape

    for {scope, scape} <- Enum.uniq(sensor_scapes ++ actuator_scapes) do
      case scope do
        :private -> 
          {scape, scape.Simulation.start_link([])}
        :public ->
          {scape, scape.Simulation.pid()}
        _ ->
          IO.puts "Unexpected scape during initialization #{scope}, #{scape}"
      end
    end
  end

	defp init_neurons([neuron|rest], cortex_pid, nsup, acc ) do
		{:ok, pid} = Phenotype.Neuron.Supervisor.start_child(nsup, [neuron, cortex_pid])
		id = neuron.id
		init_neurons(rest, cortex_pid, nsup, Map.put(acc, id, pid))
	end

	defp init_neurons([], _cortex_pid, _nsup, acc) do 
		acc
	end

	defp init_actuators([actuator|rest], cortex_pid, asup, acc ) do
		{:ok, pid} = Phenotype.Actuator.Supervisor.start_child(asup, [actuator, cortex_pid])
		id = actuator.id
		init_neurons(rest, cortex_pid, asup, Map.put(acc, id, pid))
	end

	defp init_actuators([], _cortex_pid, _asup, acc) do 
		acc
	end

	defp init_sensors([sensor|rest], cortex_pid, ssup, acc ) do
		{:ok, pid} = Phenotype.Sensor.Supervisor.start_child(ssup, [sensor, cortex_pid])
		id = sensor.id
		init_neurons(rest, cortex_pid, ssup, Map.put(acc, id, pid))
	end

	defp init_sensors([], _cortex_pid, _ssup, acc) do 
		acc
	end

	# Make the binding
	defp bind_neurons([neuron|rest], refs) do
		inputs = for input <- neuron.input_ids do
      if input.id != :biais do 
        {refs[input.id], input.weight, input.id}
      else
        # -1 because otherwise the find algo in Neuron (that matches pids) would fail.
        # Note: a somewhat better man would use a Dict to do this ...
        {:biais, input.weight, -1}
      end
    end
		outputs = for output <- neuron.output_ids, do: refs[output]
		Phenotype.Neuron.update(refs[neuron.id], inputs, outputs)
		bind_neurons(rest, refs)
	end

	defp bind_neurons([], _refs) do 
	end

	defp bind_actuators([actuator|rest], scapes_pids, refs) do
    {_, name} = actuator.scape
    {_, pid} = List.findkey(scapes_pids,name, 0) 
		outputs = Map.take(refs, actuator.fanin_ids)
		Phenotype.Actuator.update(refs[actuator.id], Map.values(outputs), pid)
		bind_actuators(rest,scapes_pids, refs)
	end

	defp bind_actuators([],_scapes, _refs) do 
	end

	defp bind_sensors([sensor|rest], scapes_pids, refs) do
    {_, name} = sensor.scape
    {_, pid} = List.findkey(scapes_pids,name, 0) 
		inputs = Map.take(refs, sensor.fanout_ids)
		Phenotype.Sensor.update(refs[sensor.id],Map.values(inputs), pid)
		bind_sensors(rest, scapes_pids, refs)
	end

	defp bind_sensors([],_scapes, _refs) do 
	end
end
