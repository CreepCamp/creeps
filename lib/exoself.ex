defmodule ExoSelf do
	use GenServer

	def start_link(opts) do 
		GenServer.start_link(__MODULE__, opts, [])
	end

	def init(opts) do 
		IO.puts "Initilizing #{__MODULE__}"
		
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
		IO.puts "Cortex fired, #{inspect asup} #{inspect ssup} #{inspect nsup}"

		# reading the json file. ensuring that everything is in place :)
		# dont know why he needs ets to do the job.
		json = Poison.decode!(File.read!(state.filename), keys: :atoms!)

		cortex = json.cortex
		neurons = json.neurons
		actuators = json.actuators
		sensors = json.sensors

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
		bind_actuators(actuators, refs)
		bind_sensors(sensors, refs)

    # By the book, the cortex here should start working ...
    # As there aren't any trainer right now it should ask the cortex 
    # to do the job several hundreds of times
    Phenotype.Cortex.start(cortex_pid, 10)

		{:noreply, Map.put(state, :content,json)}
	end


  # Note : neurons_n_weight follow this logic :
  # [{neuron_id, [{pid, weigth, id} = input] = inputs ]}
  def handle_cast({:finished, neurons_n_weight}, state ) do
    IO.puts "Yeah Cortex finished ! Hourray"

    # Now that we're finished, saves the status of the NN to file (update)
    # Current file is store in state under content

    # neurons here follows this rules ( from genotype/neuron )
    # defstruct id: nil, layer: 0, cortex_id: nil, activation_function: nil, input_ids: [], output_ids: [], vector_length: 1
    # Updating the struct should be simple enough. find the matching id.
    oldlist = state.content.neurons
    
    newlist = for n <- neurons_n_weight do
      # working through each neurons, find the appropriate neuron, then plop
      # sadly for me, they're a list of Maps, thus, we can't use List.keyfind(list, item, pos)
      update_neuron(n, oldlist)
    end

		genotype = Poison.encode! %{cortex: state.content.cortex, sensors: state.content.sensors, 
      actuators: state.content.actuators, neurons: newlist}

		File.write("#{state.filename}.json", genotype)

    send state.pid, {:finished, self()}
    {:noreply, state} 
  end

  defp update_neuron({id, input_weights} = neuron, [oldneuron|file_neurons]) do 
    if id == oldneuron.id do 
      # Note: input weights : {pid, weight, id}
      # Note: old inputs : {id, weight} 
      new_inputs = for {_,w,i} <- input_weights, do: %{id: i,weight:  w}
      %{oldneuron| input_ids: new_inputs}
    else
      update_neuron(neuron,file_neurons)
    end
  end

  def find_neuron_for_save({id,_}, []), do: IO.puts "Failed to find neuron ided #{id} for genotype update"


	# Initialize all processes. 
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
      if input.id != "biais" do 
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

	defp bind_actuators([actuator|rest], refs) do
		outputs = Map.take(refs, actuator.fanin_ids)
		Phenotype.Actuator.update(refs[actuator.id], Map.values(outputs))
		bind_actuators(rest, refs)
	end

	defp bind_actuators([], _refs) do 
	end

	defp bind_sensors([sensor|rest], refs) do
		inputs = Map.take(refs, sensor.fanout_ids)
		Phenotype.Sensor.update(refs[sensor.id],Map.values(inputs))
		bind_sensors(rest, refs)
	end

	defp bind_sensors([], _refs) do 
	end
end
